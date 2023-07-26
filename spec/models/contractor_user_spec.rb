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

require 'rails_helper'

RSpec.describe ContractorUser, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor_user) { FactoryBot.create(:contractor_user)}

  before do
    FactoryBot.create(:system_setting)
  end

  describe '#create_user' do
    let(:contractor_user2) { FactoryBot.create(:contractor_user, create_user: jv_user, update_user: contractor_user)}

    it 'jv_userの名前がマスキングされること' do
      expect(contractor_user2.masked_create_user.full_name).to eq I18n.t('consts.jv_user_name_for_contractor_user')
      expect(contractor_user2.masked_update_user.full_name).to eq 'Contractor Taro'
    end
  end

  describe '#create_user' do
    let(:contractor_user2) { FactoryBot.create(:contractor_user, create_user: contractor_user, update_user: jv_user)}

    it 'jv_userの名前がマスキングされること' do
      expect(contractor_user2.masked_create_user.full_name).to eq 'Contractor Taro'
      expect(contractor_user2.masked_update_user.full_name).to eq I18n.t('consts.jv_user_name_for_contractor_user')
    end
  end

  describe '重複エラーチェック' do
    it 'user_nameの重複でエラーに なる こと' do
      contractor_user2 = FactoryBot.build(:contractor_user, user_name: contractor_user.user_name)
      contractor_user2.valid?
      expect(contractor_user2.errors.messages[:user_name]).to eq ["has already been taken"]
    end

    it 'mobile_numberの重複でエラーに ならない こと' do
      contractor_user2 = FactoryBot.build(:contractor_user, mobile_number: contractor_user.mobile_number)
      contractor_user2.valid?
      expect(contractor_user2.errors.messages[:mobile_number]).to eq []
    end

    it '削除したcontractor_userのuser_nameの重複でエラーに ならない こと' do
      contractor_user2 = FactoryBot.build(:contractor_user, user_name: contractor_user.user_name)
      contractor_user.update!(deleted: true)
      contractor_user2.valid?
      expect(contractor_user2.errors.messages[:user_name]).to eq []
    end

    it '削除したcontractor_userのmobile_numberの重複でエラーに ならない こと' do
      contractor_user2 = FactoryBot.build(:contractor_user, mobile_number: contractor_user.mobile_number)
      contractor_user.update!(deleted: true)
      contractor_user2.valid?
      expect(contractor_user2.errors.messages[:mobile_number]).to eq []
    end
  end

  describe 'valid_passcode?' do
    it '正常' do
      contractor_user = FactoryBot.build(:contractor_user,
        rudy_passcode: '123456',
        rudy_passcode_created_at: Time.zone.now
      )

      expect(contractor_user.valid_passcode?('123456')).to eq true
      expect(contractor_user.valid_passcode?(123456)).to eq true
    end

    it 'passcode未登録' do
      contractor_user = FactoryBot.build(:contractor_user,
        rudy_passcode: nil,
        rudy_passcode_created_at: Time.zone.now
      )

      expect(contractor_user.valid_passcode?('123456')).to eq false
    end

    it 'passcode不一致' do
      contractor_user = FactoryBot.build(:contractor_user,
        rudy_passcode: '111111',
        rudy_passcode_created_at: Time.zone.now
      )

      expect(contractor_user.valid_passcode?('222222')).to eq false
    end
  end

  describe 'expired_passcode?' do
    it '期限切れ' do
      contractor_user = FactoryBot.build(:contractor_user,
        rudy_passcode: '111111',
        rudy_passcode_created_at: Time.zone.now - 16.minutes
      )

      expect(contractor_user.expired_passcode?).to eq true
    end

    it '期限内' do
      contractor_user = FactoryBot.build(:contractor_user,
        rudy_passcode: '111111',
        rudy_passcode_created_at: Time.zone.now - 14.minutes
      )

      expect(contractor_user.expired_passcode?).to eq false
    end
  end

  describe 'agreed_latest_pdpa?' do
    let(:pdpa_version1) { FactoryBot.create(:pdpa_version, version: 1) }
    let(:pdpa_version2) { FactoryBot.create(:pdpa_version, version: 2) }

    it 'PDPAのデータがない場合は同意したとみなす' do
      expect(contractor_user.agreed_latest_pdpa?).to eq true
    end

    xcontext '施工前' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20220531')
        SystemSetting.update!(require_pdpa_ymd: '20220601')

        pdpa_version1
        pdpa_version2
      end

      context '最新バージョンに同意しないを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version2, agreed: false)
        end

        it '施工前は同意しないを選択してもtrueが返ること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq true
        end
      end

      context '最新バージョンに同意するを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version2, agreed: true)
        end

        it '判定がtrueになること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq true
        end
      end

      context '古いバージョンに同意するを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version1, agreed: true)
        end

        it '最新バージョンのデータがない場合は判定がfalseになること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq false
        end
      end
    end

    context '施工後' do
      before do
        FactoryBot.create(:business_day)

        pdpa_version1
        pdpa_version2
      end

      context '最新バージョンに同意しないを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version2, agreed: false)
        end

        it '施工後は同意しないを選択した場合は判定がfalseになること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq false
        end
      end

      context '最新バージョンに同意するを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version2, agreed: true)
        end

        it '判定がtrueになること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq true
        end
      end

      context '古いバージョンに同意するを選択したデータあり' do
        before do
          FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
            pdpa_version: pdpa_version1, agreed: true)
        end

        it '最新バージョンのデータがない場合は判定がfalseになること' do
          expect(contractor_user.agreed_latest_pdpa?).to eq false
        end
      end
    end
  end

  describe 'require_agree_terms_of_service_types' do
    let(:contractor) { contractor_user.contractor }

    context 'not sub_dealer' do
      context '最新バージョンに同意' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 2,
            cpac_terms_of_service_version: 2,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
          FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)

          FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 2)
          FactoryBot.create(:terms_of_service_version, :cpac, contractor_user: contractor_user, version: 2)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm, :cpac]
          expect(contractor_user.require_agree_terms_of_service_types).to eq []
        end
      end

      context '同意なし' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 1,
            cpac_terms_of_service_version: 1,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
          FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm, :cpac]
          expect(contractor_user.require_agree_terms_of_service_types).to eq [:cbm, :cpac]
        end
      end

      context '同意バージョンが古い' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 2,
            cpac_terms_of_service_version: 2,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
          FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)

          FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 1)
          FactoryBot.create(:terms_of_service_version, :cpac, contractor_user: contractor_user, version: 1)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm, :cpac]
          expect(contractor_user.require_agree_terms_of_service_types).to eq [:cbm, :cpac]
        end
      end
    end

    context 'sub_dealer' do
      before do
        contractor.sub_dealer!
      end

      context '最新バージョンに同意' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 2,
            sub_dealer_terms_of_service_version: 2,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)

          FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 2)
          FactoryBot.create(:terms_of_service_version, :sub_dealer, contractor_user: contractor_user, version: 2)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm]
          expect(contractor_user.require_agree_terms_of_service_types).to eq []
        end
      end

      context '同意なし' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 1,
            sub_dealer_terms_of_service_version: 1,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm]
          expect(contractor_user.require_agree_terms_of_service_types).to eq [:cbm, :sub_dealer]
        end
      end

      context '同意バージョンが古い' do
        before do
          SystemSetting.first.update!(
            cbm_terms_of_service_version: 2,
            sub_dealer_terms_of_service_version: 2,
          )

          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)

          FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 1)
        end

        it '同意なし' do
          expect(contractor.enabled_limit_dealer_types).to eq [:cbm]
          expect(contractor_user.require_agree_terms_of_service_types).to eq [:cbm, :sub_dealer]
        end
      end
    end

    context '統合版規約' do
      before do
        contractor.update!(use_only_credit_limit: true)
      end

      context '最新バージョンに同意' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it '同意の必要なし' do
          expect(contractor_user.require_agree_terms_of_service_types).to eq []
        end
      end

      context '同意なし' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)
        end

        it '同意なしの判定に含まれること' do
          expect(contractor_user.require_agree_terms_of_service_types).to eq [
            TermsOfServiceVersion::INTEGRATED
          ]
        end
      end

      context '同意バージョンが古い' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 2)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it '含まれること' do
          expect(contractor_user.require_agree_terms_of_service_types).to eq [
            TermsOfServiceVersion::INTEGRATED
          ]
        end
      end
    end
  end

  describe 'exists_not_agreed_terms_of_service?' do
    let(:contractor) { contractor_user.contractor }
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    context 'cbm規約に同意済み' do
      before do
        FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
        FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 1)
        SystemSetting.update!(cbm_terms_of_service_version: 1)
      end

      context 'cbmの引数あり' do
        it 'cbmは同意済みなのでfalseになること' do
          expect(contractor_user.exists_not_agreed_terms_of_service?(:cbm)).to eq false
        end
      end

      context 'cpacの引数あり' do
        it 'cpacは同意していないのでtrueになること' do
          expect(contractor_user.exists_not_agreed_terms_of_service?(:cpac)).to eq true
        end
      end

      context '引数なし' do
        it '全てに同意しているのでfalseになること' do
          expect(contractor_user.exists_not_agreed_terms_of_service?).to eq false
        end
      end

      context 'cpac規約の同意なし' do
        before do
          FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)
        end

        context 'cbmの引数あり' do
          it 'cbmは同意済みなのでfalseになること' do
            expect(contractor_user.exists_not_agreed_terms_of_service?(:cbm)).to eq false
          end
        end

        context '引数なし' do
          it '全てに同意していないのでtrueになること' do
            expect(contractor_user.exists_not_agreed_terms_of_service?).to eq true
          end
        end
      end
    end

    context '統合版規約' do
      before do
        contractor.update!(use_only_credit_limit: true)
      end

      context '最新バージョンに同意' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it 'false' do
          expect(contractor_user.exists_not_agreed_terms_of_service?).to eq false
        end
      end

      context '同意なし' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)
        end

        it '一度も同意していない場合は true' do
          expect(contractor_user.exists_not_agreed_terms_of_service?).to eq true
        end
      end

      context '同意バージョンが古い' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 2)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it '一度でも同意していれば false' do
          expect(contractor_user.exists_not_agreed_terms_of_service?).to eq false
        end
      end
    end

    context 'individual' do
      before do
        contractor.individual!
      end

      describe 'DealerTypeの指定' do
        context 'cbmに同意済み。individualの同意なし' do
          before do
            eligibility = FactoryBot.create(:eligibility, contractor: contractor)
            FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)

            FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user, version: 1)
          end

          it 'dealer_typeを指定しても individualが未同意なら trueになること' do
            expect(contractor_user.require_agree_terms_of_service_types).to eq [:individual]

            expect(contractor_user.exists_not_agreed_terms_of_service?(:cbm)).to eq true
          end
        end
      end
    end
  end

  describe 'updated_terms_of_service?' do
    let(:contractor) { contractor_user.contractor }

    context '統合版規約' do
      before do
        contractor.update!(use_only_credit_limit: true)
      end

      context '最新バージョンに同意' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it 'false' do
          expect(contractor_user.updated_terms_of_service?).to eq false
        end
      end

      context '同意なし' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 1)
        end

        it '一度も同意していない場合は false' do
          expect(contractor_user.updated_terms_of_service?).to eq false
        end
      end

      context '同意バージョンが古い' do
        before do
          SystemSetting.first.update!(integrated_terms_of_service_version: 2)

          FactoryBot.create(:terms_of_service_version, :integrated, contractor_user: contractor_user,
            version: 1)
        end

        it 'true' do
          expect(contractor_user.updated_terms_of_service?).to eq true
        end
      end
    end
  end

  describe 'agree_terms_of_service' do
    let(:contractor) { contractor_user.contractor }

    context '統合版規約' do
      it '正常に作成されること' do
        contractor_user.agree_terms_of_service(TermsOfServiceVersion::INTEGRATED, 2)

        expect(
          TermsOfServiceVersion.exists?(contractor_user: contractor_user, integrated: true, version: 2)
        ).to eq true
      end
    end

    context 'sub_dealer' do
      it '正常に作成されること' do
        contractor_user.agree_terms_of_service(:sub_dealer, 2)

        expect(
          TermsOfServiceVersion.exists?(contractor_user: contractor_user, sub_dealer: true, version: 2)
        ).to eq true
      end
    end

    context 'cbm' do
      it '正常に作成されること' do
        contractor_user.agree_terms_of_service(:cbm, 2)

        expect(
          TermsOfServiceVersion.exists?(contractor_user: contractor_user, dealer_type: :cbm, version: 2)
        ).to eq true
      end
    end
  end

  describe 'delete_with_auth_tokens' do
    it '正常に削除されること' do
      contractor_user.delete_with_auth_tokens

      expect(contractor_user.deleted).to eq 1

      # 項目がマスキングされること
      expect(contractor_user.user_name).to eq '0000000000000'
    end
  end
end
