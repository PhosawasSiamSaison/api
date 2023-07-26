# frozen_string_literal: true

class RegisterOnlineProcessingContractor
  include ImageModule

  def call(params)
    contractor = Contractor.new(create_contractor_params(params))
    contractor_user = ContractorUser.new(create_contractor_user_params(params))

    # ContractorUserの検証
    contractor_user.contractor = contractor
    contractor_user.full_name = params[:contractor_user][:th_name]

    if contractor_user.invalid?
      Rails.logger.info contractor_user.errors.details.inspect

      return 'invalid_contractor_user'
    end


    # オンライン申請用の設定
    if JvService::Application.config.try(:no_use_only_credit_limit)
      contractor.use_only_credit_limit = false
    else
      contractor.use_only_credit_limit = true
    end

    contractor.application_type = :applied_online
    contractor.application_number = Contractor.generate_application_number
    contractor.approval_status = :pre_registration # 本人画像登録前のステータス

    # Paper用の書類チェックはONへ
    contractor.doc_company_registration    = true
    contractor.doc_vat_registration        = true
    contractor.doc_owner_id_card           = true
    contractor.doc_authorized_user_id_card = true

    contractor.authorized_person_same_as_owner = true
    contractor.contact_person_same_as_owner    = true

    # Owner属性の設定
    contractor_user_params = params.fetch(:contractor_user)
    contractor.owner_personal_id   = contractor_user_params.fetch(:user_name)
    contractor.owner_mobile_number = contractor_user_params.fetch(:mobile_number)
    contractor.owner_email         = contractor_user_params.fetch(:email)
    contractor.th_owner_name       = contractor_user_params.fetch(:th_name)
    contractor.en_owner_name       = contractor_user_params.fetch(:en_name)
    contractor.owner_line_id       = contractor_user_params.fetch(:line_id)
    contractor.owner_sex           = :unselected

    # その他の設定
    contractor.registered_at = Time.zone.now

    if contractor.invalid?
      Rails.logger.info contractor.errors.details.inspect

      return 'invalid_contractor'
    end

    documents = params[:documents].presence || {}

    ActiveRecord::Base.transaction do
      # オンライン申請の書類の添付
      contractor.attach_documents(documents)

      # トークンの作成
      contractor.online_apply_token = Contractor.generate_online_apply_token

      contractor.save!
    rescue => e
      Rails.logger.info e.inspect

      return 'invalid_documents'
    end

    [nil, contractor]
  end

  private
    def create_contractor_params(params)
      params.require(:contractor).permit(
        :tax_id,
        :th_company_name,
        :en_company_name,
        :phone_number,
        :employee_count,
        :establish_year,
        :shareholders_equity,
        :capital_fund_mil,
        :recent_revenue,
        :short_term_loan,
        :long_term_loan,
        :recent_profit,
        :apply_from,
      )
    end

    def create_contractor_user_params(params)
      params.require(:contractor_user).permit(
        :user_name,
        :mobile_number,
        :email,
        :line_id
      )
    end
end
