# frozen_string_literal: true
# == Schema Information
#
# Table name: contractor_users
#
#  id                       :bigint(8)        not null, primary key
#  contractor_id            :integer          not null
#  user_type                :integer          default(NULL), not null
#  user_name                :string(20)       not null
#  full_name                :string(40)       not null
#  mobile_number            :string(15)
#  title_division           :string(40)
#  email                    :string(200)
#  line_id                  :string(20)
#  line_user_id             :string(255)
#  line_nonce               :string(255)
#  initialize_token         :string(30)
#  verify_mode              :integer          default("verify_mode_otp"), not null
#  verify_mode_otp          :string(10)
#  login_failed_count       :integer          default(0), not null
#  rudy_passcode            :string(10)
#  rudy_passcode_created_at :datetime
#  rudy_auth_token          :string(30)
#  password_digest          :string(255)
#  temp_password            :string(15)
#  create_user_type         :string(255)
#  create_user_id           :integer
#  update_user_type         :string(255)
#  update_user_id           :integer
#  deleted                  :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  operation_updated_at     :datetime
#  lock_version             :integer          default(0)
#

class ContractorUser < ApplicationRecord
  include UserModule

  default_scope { where(deleted: 0) }
  has_secure_password validations: false

  belongs_to :contractor
  belongs_to :create_user, polymorphic: true, optional: true, unscoped: true
  belongs_to :update_user, polymorphic: true, optional: true, unscoped: true

  has_many :evidences
  has_many :auth_tokens, :as => :tokenable
  has_many :create_contractor_users, class_name: :ContractorUser, as: :create_user
  has_many :update_contractor_users, class_name: :ContractorUser, as: :update_user
  has_many :agreed_terms_of_services, class_name: :TermsOfServiceVersion

  has_many :contractor_user_pdpa_versions
  has_many :pdpa_versions, through: :contractor_user_pdpa_versions

  has_many :agreed_contractor_user_pdpa_versions, -> { agreed }, class_name: "ContractorUserPdpaVersion"
  has_many :agreed_pdpa_versions, through: :agreed_contractor_user_pdpa_versions, source: "pdpa_version"

  enum user_type: { owner: 1, authorized: 2, contact: 3, other: 4 }
  enum verify_mode: { verify_mode_otp: 1, verify_mode_login_passcode: 2 }

  validates :user_name, presence: true, length: { is: 13 },
    uniqueness: { conditions: -> { where(deleted: 0) }, case_sensitive: false },
    numericality: { only_integer: true, allow_blank: true }

  validates :full_name, presence: true, length: { maximum:40 }

  validates :mobile_number, presence: true, length: { maximum: 11 },
    numericality: { only_integer: true, allow_blank: true }

  validates :password, presence: true, on: :password_update
  validates :password, length: { is: 6 },
    numericality: { only_integer: true },
    allow_blank: true 

  # SMSのターゲット
  scope :sms_targets, -> { where(user_type: %w(owner authorized contact)) }

  def generate_initialize_token
    loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token unless ContractorUser.exists?(initialize_token: random_token)
    end
  end

  def gen_rudy_passcode
    ((0..9).to_a).sample(6).join
  end

  def generate_otp
    gen_rudy_passcode
  end

  # PDPAの同意チェック
  def agreed_latest_pdpa?
    return true if PdpaVersion.all.blank?

    agreed_pdpa_versions.latest?
  end

  # 最新のPDPAに同意したレコードを作成する
  def create_latest_pdpa_agreement!
    return if PdpaVersion.latest.blank?

    # agreed: 0 がある場合に取得する
    contractor_user_pdpa_version =
      contractor_user_pdpa_versions.find_or_initialize_by(pdpa_version: PdpaVersion.latest)

    # agreed: 1 で 作成 or 更新
    contractor_user_pdpa_version.update!(agreed: true)
  end

  # 対象の規約のタイプ(DealerTypeLimitを設定しているDealerTypeとSubDealerの設定)
  def target_terms_of_service_types
    # 統合版は一つだけ返す
    return [TermsOfServiceVersion::INTEGRATED] if contractor.use_only_credit_limit

    types = contractor.enabled_limit_dealer_types

    types.push(TermsOfServiceVersion::SUB_DEALER) if contractor.sub_dealer?
    types.push(TermsOfServiceVersion::INDIVIDUAL) if contractor.individual?

    types
  end

  # 対象の規約に一度も同意していないかの判定(対象の規約に１度でも同意していればfalseが返る)
  # (初回の同意か更新した規約への同意かを分けている。フロントで表示を変える想定)
  # (ログイン後の判定と各APIで使用)
  # (規約バージョンは見ずに同意済みレコードがあるかのみを判定)
  def exists_not_agreed_terms_of_service?(dealer_type = nil)
    # 統合版の判定
    if contractor.use_only_credit_limit
      return !agreed_terms_of_services.find_by_type(TermsOfServiceVersion::INTEGRATED)
    end

    # 指定のDealerTypeがDealerTypeLimitで設定されていなければ trueを返す
    return true if dealer_type.present? && !target_terms_of_service_types.include?(dealer_type.to_sym)

    target_terms_of_service_types.any? do |terms_of_service_type|
      # 引数の指定がある場合はそのDealerTypeのみをチェックする(それ以外をスキップ)
      if dealer_type.present? && dealer_type.to_sym != terms_of_service_type
        # ただし sub_dealer の場合はスキップしない
        # (dealer_typeの指定はオーダー時のチェックで使用するが、dealer_typeに関係なく
        # contractorがsub_dealerの場合はsub_dealerの規約チェックが必要なので)
        next unless [
          TermsOfServiceVersion::SUB_DEALER,
          TermsOfServiceVersion::INDIVIDUAL
        ].include?(terms_of_service_type)
      end

      agreed_terms_of_services.find_by_type(terms_of_service_type).blank?
    end
  end

  # 同意した規約が更新されているか
  def updated_terms_of_service?(dealer_type = nil)
    # 統合版の判定
    if contractor.use_only_credit_limit
      agreed_terms_of_service = agreed_terms_of_services.find_by_type(TermsOfServiceVersion::INTEGRATED)

      # 更新のみを見るので未同意は含まない
      return false if agreed_terms_of_service.blank?

      latest_version = SystemSetting.get_terms_of_service_version(TermsOfServiceVersion::INTEGRATED)

      # 最新のバージョンと一致しない
      return latest_version != agreed_terms_of_service.version
    end

    # 指定のDealerTypeがDealerTypeLimitで設定されていなければ trueを返す
    return true if dealer_type.present? && !target_terms_of_service_types.include?(dealer_type.to_sym)

    # 対象の規約のみをチェックする
    target_terms_of_service_types.any? do |terms_of_service_type|
      # 引数の指定がある場合はそのDealerTypeのみをチェックする(それ以外をスキップ)
      if dealer_type.present? && dealer_type.to_sym != terms_of_service_type
        # ただし sub_dealer の場合はスキップしない
        # (dealer_typeの指定はオーダー時のチェックで使用するが、dealer_typeに関係なく
        # contractorがsub_dealerの場合はsub_dealerの規約チェックが必要なので)
        next unless [
          TermsOfServiceVersion::SUB_DEALER,
          TermsOfServiceVersion::INDIVIDUAL
        ].include?(terms_of_service_type)
      end

      agreed_terms_of_service = agreed_terms_of_services.find_by_type(terms_of_service_type)

      # 更新のみを見るので未同意は含まない
      next false if agreed_terms_of_service.blank?

      latest_version = SystemSetting.get_terms_of_service_version(terms_of_service_type)

      # 最新のバージョンと一致しない
      latest_version != agreed_terms_of_service.version
    end
  end

  # 各画面と購入時のチェック(DealerTypeLimitの設定がなければチェックにはかからない)
  def not_agree_or_updated_terms_of_service?(dealer_type = nil)
    exists_not_agreed_terms_of_service?(dealer_type) || updated_terms_of_service?(dealer_type)
  end

  # 同意が必要な規約のタイプを配列で返す
  def require_agree_terms_of_service_types
    target_terms_of_service_types.select {|type|
      agreed_terms_of_service = agreed_terms_of_services.find_by_type(type)

      next true if agreed_terms_of_service.nil?

      agreed_terms_of_service.version != SystemSetting.get_terms_of_service_version(type)
    }
  end

  # 規約の同意処理
  def agree_terms_of_service(type, version)
    terms_of_service_version =
      if type == TermsOfServiceVersion::INTEGRATED
        agreed_terms_of_services.find_or_initialize_by(dealer_type: nil, integrated: true)
      elsif type == TermsOfServiceVersion::SUB_DEALER
        agreed_terms_of_services.find_or_initialize_by(dealer_type: nil, sub_dealer: true)
      elsif type == TermsOfServiceVersion::INDIVIDUAL
        agreed_terms_of_services.find_or_initialize_by(dealer_type: nil, individual: true)
      else
        agreed_terms_of_services.find_or_initialize_by(dealer_type: type)
      end

    terms_of_service_version.update!(version: version)
  end

  def masked_create_user
    mask_user(create_user)
  end

  def masked_update_user
    mask_user(update_user)
  end

  def user_type_label
    enum_to_label('user_type')
  end

  def verify_mode_label
    enum_to_label('verify_mode')
  end

  def valid_passcode?(one_time_passcode)
    rudy_passcode.present? && rudy_passcode == one_time_passcode.to_s
  end

  def expired_passcode?
    (rudy_passcode_created_at + SystemSetting.order_one_time_passcode_limit.minutes) < Time.zone.now
  end

  def is_linked_line_account?
    line_user_id.present?
  end

  def use_verify_otp_mode?
    verify_mode_otp? && SystemSetting.one_time_passcode?
  end

  private
  # ContractorUserにはJv担当者の名前を見せないようにする
  def mask_user(user)
    if user.is_a?(JvUser)
      user.user_name = I18n.t('consts.jv_user_name_for_contractor_user')
      user.full_name = I18n.t('consts.jv_user_name_for_contractor_user')
    end

    user
  end
end
