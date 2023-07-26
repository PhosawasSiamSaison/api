require 'rails_helper'

RSpec.describe Jv::ChangeProductApplyListController, type: :controller do

  describe 'GET - search' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }

    before do
      contractor1 = FactoryBot.create(:contractor, tax_id: '1234567890123',
        en_company_name: 'Hoge')
      contractor2 = FactoryBot.create(:contractor, tax_id: '2234567890123',
        en_company_name: 'Fuga')

      FactoryBot.create(:change_product_apply, contractor: contractor1)
      FactoryBot.create(:change_product_apply, :completed, contractor: contractor2)
    end

    it 'tax id の検索(前方一致)が正しいこと' do
      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "12",
          company_name: "",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 1

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:contractor][:tax_id]).to eq '1234567890123'

      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "22",
          company_name: "",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 1

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:contractor][:tax_id]).to eq '2234567890123'
    end

    it 'Company Name の検索(中間一致)が正しいこと' do
      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "Ho",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 1

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:contractor][:en_company_name]).to eq 'Hoge'

      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "uga",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 1

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:contractor][:en_company_name]).to eq 'Fuga'
    end

    it 'Include Completed の検索が正しいこと' do
      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 2

      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "",
          include_completed: false,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:contractor][:completed_at].blank?).to eq true
    end

    it 'レスポンス項目が正しく返ること' do
      params = {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "Fuga",
          include_completed: true,
        },
      }

      get :search, params: params
      expect(res[:success]).to eq true
      expect(res[:change_product_applies].count).to eq 1

      res_change_product_apply = res[:change_product_applies].first
      expect(res_change_product_apply[:applied_at].present?).to eq true
      expect(res_change_product_apply[:contractor][:th_company_name].present?).to eq true
      expect(res_change_product_apply[:due_ymd].present?).to eq true
    end
  end

  describe 'GET - detail' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      FactoryBot.create(:business_day)
      FactoryBot.create(:system_setting)
    end

    context '登録 前' do
      let(:change_product_apply) {
        FactoryBot.create(:change_product_apply, contractor: contractor)
      }
      let(:order) {
        order = FactoryBot.create(:order, :applied_change_product, contractor: contractor,
          change_product_apply: change_product_apply)
      }

      before do
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常値' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
        }

        get :detail, params: params

        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1

        res_order = res[:orders].first
        expect(res_order[:change_product_status][:code]).to eq 'applied'

        expect(res_order[:after].has_key?(:total_amount)).to eq true

        expect(res[:memo]).to eq nil
        expect(res[:can_register]).to eq true
        expect(res[:completed_at]).to eq nil
        expect(res[:register_user_name]).to eq nil
      end
    end

    context '承認後' do
      let(:change_product_apply) {
        FactoryBot.create(:change_product_apply, :completed, contractor: contractor)
      }
      let(:order) {
        order = FactoryBot.create(:order, :approved_change_product, contractor: contractor,
        change_product_apply: change_product_apply)
      }

      before do
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常値' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
        }

        get :detail, params: params

        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1

        res_order = res[:orders].first
        expect(res_order[:change_product_status][:code]).to eq 'approval'

        expect(res[:memo]).to eq 'completed'
        expect(res[:can_register]).to eq false
        expect(res[:completed_at].present?).to eq true
        expect(res[:register_user_name].present?).to eq true
      end
    end

    context '却下後' do
      let(:change_product_apply) {
        FactoryBot.create(:change_product_apply, :completed, contractor: contractor)
      }
      let(:order) {
        order = FactoryBot.create(:order, :rejected_change_product, contractor: contractor,
        change_product_apply: change_product_apply)
      }

      before do
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常値' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
        }

        get :detail, params: params

        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1

        res_order = res[:orders].first
        expect(res_order[:change_product_status][:code]).to eq 'rejected'

        expect(res[:memo]).to eq 'completed'
        expect(res[:can_register]).to eq false
        expect(res[:completed_at].present?).to eq true
        expect(res[:register_user_name].present?).to eq true
      end
    end
  end

  describe 'PATCH - approve' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day)
    end

    context '承認か却下' do
      let(:change_product_apply) {
        FactoryBot.create(:change_product_apply, contractor: contractor)
      }
      let(:order) {
        FactoryBot.create(:order, :applied_change_product, :inputed_date,
          contractor: contractor, change_product_apply: change_product_apply)
      }

      before do
        payment = FactoryBot.create(:payment, contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '承認' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
          orders: [
            {
              id: order.id,
              change_product_status: 'approval'
            },
          ],
          memo: 'all approve'
        }

        patch :approve, params: params

        expect(res[:success]).to eq true
        
        change_product_apply.reload
        expect(change_product_apply.completed_at.present?).to eq true
        expect(change_product_apply.memo).to eq 'all approve'
        expect(change_product_apply.register_user).to eq jv_user

        order.reload
        expect(order.change_product_status).to eq 'approval'
        expect(order.is_applying_change_product).to eq false
        expect(order.product_changed_at.present?).to eq true
        expect(order.product_changed_user).to eq jv_user
      end

      it '却下' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
          orders: [
            {
              id: order.id,
              change_product_status: 'rejected'
            },
          ],
          memo: 'all reject'
        }

        patch :approve, params: params
        expect(res[:success]).to eq true
        
        change_product_apply.reload
        expect(change_product_apply.completed_at.present?).to eq true
        expect(change_product_apply.memo).to eq 'all reject'
        expect(change_product_apply.register_user).to eq jv_user

        order.reload
        expect(order.change_product_status).to eq 'rejected'
        expect(order.is_applying_change_product).to eq false
        expect(order.product_changed_at.present?).to eq true
        expect(order.product_changed_user).to eq jv_user
      end

      context '登録後のsms送信' do
        before do
          FactoryBot.create(:contractor_user, contractor: contractor)
        end

        let(:params) {
          {
            auth_token: auth_token.token,
            change_product_apply_id: change_product_apply.id,
            orders: [
              {
                id: order.id,
                change_product_status: 'approval'
              },
            ],
            memo: 'all approve'
          }
        }

        it '登録後にsmsが送られること' do
          patch :approve, params: params

          expect(res[:success]).to eq true
          
          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first

          expect(sms.message_body.present?).to eq true
          expect(sms.message_type).to eq "approval_change_product"
        end

        context 'stop_payment_sms: true' do
          before do
            contractor.update!(stop_payment_sms: true)
          end

          it 'smsが送られないこと' do
            patch :approve, params: params

            expect(res[:success]).to eq true
            
            expect(SmsSpool.count).to eq 0
          end
        end
      end

      describe '権限チェック' do
        let(:staff) { FactoryBot.create(:jv_user, :staff) }
        let(:staff_token) { FactoryBot.create(:auth_token, tokenable: staff).token }

        it 'md以外はエラー' do
          params = {
            auth_token: staff_token,
            change_product_apply_id: change_product_apply.id,
            orders: [
              {
                id: order.id,
                change_product_status: 'approval'
              },
            ],
            memo: 'all approve'
          }

          patch :approve, params: params

          expect(res[:success]).to eq false
          expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
        end
      end
    end

    context '承認と却下' do
      let(:change_product_apply) {
        FactoryBot.create(:change_product_apply, contractor: contractor)
      }
      let(:order1) {
        FactoryBot.create(:order, :applied_change_product, :inputed_date,
          contractor: contractor, change_product_apply: change_product_apply)
      }
      let(:order2) {
        FactoryBot.create(:order, :applied_change_product, :inputed_date,
          contractor: contractor, change_product_apply: change_product_apply)
      }

      before do
        payment1 = FactoryBot.create(:payment, contractor: contractor)
        FactoryBot.create(:installment, order: order1, payment: payment1, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)

        payment2 = FactoryBot.create(:payment, contractor: contractor)
        FactoryBot.create(:installment, order: order2, payment: payment2, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '承認' do
        params = {
          auth_token: auth_token.token,
          change_product_apply_id: change_product_apply.id,
          orders: [
            {
              id: order1.id,
              change_product_status: 'approval'
            },
            {
              id: order2.id,
              change_product_status: 'rejected'
            },
          ],
          memo: 'approve and reject'
        }

        patch :approve, params: params
        expect(res[:success]).to eq true
        
        change_product_apply.reload
        expect(change_product_apply.completed_at.present?).to eq true
        expect(change_product_apply.memo).to eq 'approve and reject'
        expect(change_product_apply.register_user).to eq jv_user

        order1.reload
        expect(order1.change_product_status).to eq 'approval'

        order2.reload
        expect(order2.change_product_status).to eq 'rejected'
      end
    end
  end
end
