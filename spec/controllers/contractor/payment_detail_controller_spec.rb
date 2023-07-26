
RSpec.describe Contractor::PaymentDetailController, type: :controller do
  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
  end

  let(:contractor) { contractor_user.contractor }
  let(:contractor_user) { FactoryBot.create(:contractor_user)}
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user).token }

  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:product4) { Product.find_by(product_key: 4) }

  describe "GET #payment_detail" do
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102') }
    let(:payment) { FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215') }

    before do
      FactoryBot.create(:installment, order: order, payment: payment)
    end

    it "正常に取得ができること" do
      params = {
        auth_token: auth_token,
        payment_id: payment.id,
      }

      get :payment_detail, params: params

      expect(res[:success]).to eq true
      expect(res.has_key?(:allowed_change_products)).to eq true

      expect(res[:payments].has_key?(:due_ymd)).to eq true
      expect(res[:payments].has_key?(:paid_up_ymd)).to eq true
      expect(res[:payments].has_key?(:total_amount)).to eq true
      expect(res[:payments].has_key?(:status)).to eq true
      expect(res[:payments].has_key?(:due_amount)).to eq true
      expect(res[:payments].has_key?(:cashback)).to eq true
      expect(res[:payments].has_key?(:exceeded)).to eq true
      expect(res[:payments].has_key?(:paid_total_amount)).to eq true
      expect(res[:payments].has_key?(:remaining_amount)).to eq true
      expect(res[:payments].has_key?(:installments)).to eq true

      installment = res[:payments][:installments].first
      expect(installment.has_key?(:id)).to eq true
      expect(installment.has_key?(:status)).to eq true
      expect(installment.has_key?(:order)).to eq true
      expect(installment.has_key?(:dealer)).to eq true
      expect(installment.has_key?(:installment_number)).to eq true
      expect(installment.has_key?(:paid_up_ymd)).to eq true
      expect(installment.has_key?(:total_amount)).to eq true
      expect(installment.has_key?(:can_apply_change_product)).to eq true
      expect(installment.has_key?(:is_product_changed)).to eq true
      expect(installment.has_key?(:lock_version)).to eq true
    end
  end

  describe '#change_product_schedule' do
    let(:payment) { Payment.first }
    let(:order) { Order.first }

    context 'Orderを一つ作成' do
      before do
        BusinessDay.update!(business_ymd: '20190212')

        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          purchase_ymd: '20190115')

        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')

        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'product_keyをnullでafterに値が入らないこと' do
        params = {
          auth_token: auth_token,
          payment_id: payment.id,
          proudct_key: nil,
        }

        get :change_product_schedule, params: params

        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1
        expect(res[:can_apply]).to eq false

        res_order = res[:orders].first
        expect(res_order[:id]).to eq order.id
        expect(res_order[:order_number]).to eq order.order_number

        expect(res_order[:before][:count]).to eq order.installment_count
        expect(res_order[:before][:schedule].first[:amount]).to eq order.purchase_amount
        expect(res_order[:before][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res_order[:before][:schedule].first[:due_ymd]).to eq order.first_due_ymd

        expect(res_order[:after][:count]).to eq 0
        expect(res_order[:after][:schedule]).to eq []
        expect(res_order[:after][:total_amount]).to eq 0.0
      end

      it 'product_key指定でafterに値が入ること' do
        params = {
          auth_token: auth_token,
          payment_id: payment.id,
          product_key: 2,
        }

        get :change_product_schedule, params: params

        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1
        expect(res[:can_apply]).to eq true

        res_order = res[:orders].first
        expect(res_order[:id]).to eq order.id
        expect(res_order[:order_number]).to eq order.order_number

        expect(res_order[:before][:count]).to eq order.installment_count
        expect(res_order[:before][:schedule].first[:amount]).to eq order.purchase_amount
        expect(res_order[:before][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res_order[:before][:schedule].first[:due_ymd]).to eq order.first_due_ymd

        expect(res_order[:after][:count]).to eq product2.number_of_installments
        expect(res_order[:after][:schedule].is_a?(Array)).to eq true
        expect(res_order[:after][:schedule].count).to eq product2.number_of_installments
        expect(res_order[:after][:schedule].first[:due_ymd].present?).to eq true
        expect(res_order[:after][:schedule].first[:amount].present?).to eq true
        expect(res_order[:after][:schedule].first[:amount].is_a?(Float)).to eq true

        expect(res_order[:after][:total_amount]).to eq res_order[:after][:schedule].sum{|item|
          item[:amount]
        }.round(2).to_f
      end
    end
  end

  describe '#apply_change_product' do
    let(:payment) { Payment.first }
    let(:order) { Order.first }

    before do
      DealerTypeSetting.find_by(dealer_type: :cbm).update!(switch_auto_approval: false)
    end

    context 'Stale Objectエラー' do
      before do
        BusinessDay.update!(business_ymd: '20190201')

        FactoryBot.create(:order, contractor: contractor, product: product1,
          purchase_ymd: '20190115', input_ymd: '20190115')

        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        
        # 消し込みあり
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0, paid_principal: 100)
      end

      it '消し込みあり' do
        params = {
          auth_token: auth_token,
          orders: [
            {
              id: order.id,
              product_key: 2
            }
          ],
        }

        patch :apply_change_product, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.stale_object_error')]
      end
    end

    context '申請可能日超過エラー' do
      before do
        BusinessDay.update!(business_ymd: '20190213')

        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          purchase_ymd: '20190115')

        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')

        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '申請期限切れメッセージが返ること' do
        params = {
          auth_token: auth_token,
          orders: [
            {
              id: order.id,
              product_key: 2
            }
          ],
        }

        patch :apply_change_product, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.over_apply_change_product_limit_date')]
      end
    end

    context '正常値' do
      before do
        BusinessDay.update!(business_ymd: '20190212')

        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          purchase_ymd: '20190115')

        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')

        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常に更新されること' do
        params = {
          auth_token: auth_token,
          orders: [
            {
              id: order.id,
              product_key: 2
            }
          ],
        }

        patch :apply_change_product, params: params

        expect(res[:success]).to eq true

        order.reload
        expect(order.change_product_status).to eq 'applied'
        expect(order.is_applying_change_product).to eq true
        expect(order.applied_change_product).to eq product2
        expect(order.change_product_applied_at.present?).to eq true
        expect(order.change_product_applied_user).to eq contractor_user

        change_product_apply = order.change_product_apply
        expect(change_product_apply.contractor).to eq order.contractor
        expect(change_product_apply.apply_user).to eq contractor_user
        expect(change_product_apply.due_ymd).to eq payment.due_ymd
      end
    end

    describe '自動承認' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
      let(:cpac_dealer) { FactoryBot.create(:cpac_dealer) }
      let(:eligibility) {
        FactoryBot.create(:eligibility, contractor: contractor)
      }
      let(:payment) {
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
      }
      let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }

      before do
        BusinessDay.update!(business_ymd: '20190212')

        FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)
        FactoryBot.create(:terms_of_service_version, :cpac, contractor_user: contractor_user)

        site = FactoryBot.create(:site, contractor: contractor)
        order = FactoryBot.create(:order, :inputed_date, dealer: cpac_dealer,
          contractor: contractor, site: site, product: product1, purchase_ymd: '20190115')
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 1000, interest: 0)
      end

      it '自動承認されること' do
        params = {
          auth_token: auth_token,
          orders: [
            {
              id: order.id,
              product_key: 2
            }
          ],
        }

        patch :apply_change_product, params: params

        expect(res[:success]).to eq true

        order.reload
        expect(order.change_product_status).to eq 'approval'
        expect(order.is_applying_change_product).to eq false
        expect(order.applied_change_product).to eq product2
        expect(order.change_product_applied_at.present?).to eq true
        expect(order.change_product_applied_user).to eq contractor_user
        expect(order.installments.count).to eq 3

        change_product_apply = order.change_product_apply
        expect(change_product_apply.contractor).to eq order.contractor
        expect(change_product_apply.apply_user).to eq contractor_user
        expect(change_product_apply.due_ymd).to eq payment.due_ymd
        expect(change_product_apply.memo.present?).to eq true

        sms = SmsSpool.find_by(message_type: :approval_change_product)
        expect(sms.present?).to eq true
      end

      context '申請と自動承認の混合' do
        let(:cbm_order) {
          FactoryBot.create(:order, :inputed_date, dealer: cbm_dealer,
            contractor: contractor, product: product1, purchase_ymd: '20190115')
        }

        before do
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
          FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user)

          FactoryBot.create(:installment, order: cbm_order, payment: payment, installment_number: 1,
            due_ymd: '20190215', principal: 1000, interest: 0)
        end

        it '正常に処理されること' do
          params = {
            auth_token: auth_token,
            orders: [
              {
                id: order.id,
                product_key: 2
              },
              {
                id: cbm_order.id,
                product_key: 2
              }
            ]
          }

          patch :apply_change_product, params: params

          expect(res[:success]).to eq true

          # CAPC Orddr
          order.reload
          expect(order.change_product_status).to eq 'approval'
          expect(order.is_applying_change_product).to eq false
          expect(order.applied_change_product).to eq product2
          expect(order.change_product_applied_at.present?).to eq true
          expect(order.change_product_applied_user).to eq contractor_user
          expect(order.installments.count).to eq 3

          change_product_apply = order.change_product_apply
          expect(change_product_apply.contractor).to eq order.contractor
          expect(change_product_apply.apply_user).to eq contractor_user
          expect(change_product_apply.due_ymd).to eq payment.due_ymd
          expect(change_product_apply.memo.present?).to eq true
          expect(change_product_apply.completed_at.present?).to eq true

          # CBM Order
          cbm_order.reload
          expect(cbm_order.change_product_status).to eq 'applied'
          expect(cbm_order.is_applying_change_product).to eq true
          expect(cbm_order.applied_change_product).to eq product2
          expect(cbm_order.change_product_applied_at.present?).to eq true
          expect(cbm_order.change_product_applied_user).to eq contractor_user
          expect(cbm_order.installments.count).to eq 1

          change_product_apply = cbm_order.change_product_apply
          expect(change_product_apply.contractor).to eq order.contractor
          expect(change_product_apply.apply_user).to eq contractor_user
          expect(change_product_apply.due_ymd).to eq payment.due_ymd
          expect(change_product_apply.memo.present?).to eq false
          expect(change_product_apply.completed_at.present?).to eq false

          sms = SmsSpool.find_by(message_type: :approval_change_product)
          expect(sms.present?).to eq true
        end

        it '許可していない商品でエラー' do
          FactoryBot.create(:available_product, :switch, :cbm, :unavailable, product: product1, contractor: contractor)
          FactoryBot.create(:available_product, :switch, :cbm, :unavailable, product: product2, contractor: contractor)

          # 自動承認でエラー
          params = {
            auth_token: auth_token,
            orders: [
              {
                id: order.id,
                product_key: 1
              },
              {
                id: cbm_order.id,
                product_key: 2
              }
            ]
          }

          patch :apply_change_product, params: params

          expect(res[:success]).to eq false
          expect(res[:errors]).to eq [I18n.t("error_message.stale_object_error")]

          # 申請でエラー
          params = {
            auth_token: auth_token,
            orders: [
              {
                id: order.id,
                product_key: 2
              },
              {
                id: cbm_order.id,
                product_key: 1
              }
            ]
          }

          patch :apply_change_product, params: params

          expect(res[:success]).to eq false
          expect(res[:errors]).to eq [I18n.t("error_message.stale_object_error")]

          expect(ChangeProductApply.all.count).to eq 0
        end

        context '申請可能日超過' do
          before do
            BusinessDay.update!(business_ymd: '20190216')
          end

          it 'エラーが正しく返ること' do
            # 自動承認でのチェック
            params = {
              auth_token: auth_token,
              orders: [
                {
                  id: order.id,
                  product_key: 2
                }
              ]
            }

            patch :apply_change_product, params: params

            expect(res[:success]).to eq false
            expect(res[:errors]).to eq [I18n.t('error_message.over_apply_change_product_limit_date')]


            # 申請のみでのチェック
            BusinessDay.update!(business_ymd: '20190215')

            params = {
              auth_token: auth_token,
              orders: [
                {
                  id: cbm_order.id,
                  product_key: 2
                }
              ]
            }

            patch :apply_change_product, params: params

            expect(res[:success]).to eq false
            expect(res[:errors]).to eq [I18n.t('error_message.over_apply_change_product_limit_date')]
          end
        end
      end
    end
  end
end
