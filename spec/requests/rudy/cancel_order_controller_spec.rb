require 'rails_helper'

RSpec.describe Rudy::CancelOrderController, type: :request do

  describe "#call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) { Order.first }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        order_number: order.order_number,
        dealer_code: order.dealer.dealer_code
      }
    }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day, business_ymd: "20200101")
      FactoryBot.create(:rudy_api_setting)
      FactoryBot.create(:order, contractor: contractor, input_ymd: "20200101")
    end

    describe '正常パターン' do
      it '正しくキャンセルができること' do
        post rudy_cancel_order_path, params: default_params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(order.reload.canceled?).to eq true
      end

      context 'Input Dateなし' do
        before do
          order.update!(input_ymd: nil)
        end

        it '正常にキャンセルされること' do
          post rudy_cancel_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq "OK"
          expect(order.reload.canceled?).to eq true
        end
      end
    end

    describe 'エラー検証' do
      it 'input dateと異なる業務日でエラーになること' do
        order.update!(input_ymd: '20200101')
        BusinessDay.update!(business_ymd: '20200102')

        post rudy_cancel_order_path, params: default_params, headers: headers

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "input_date_not_today"

        expect(order.reload.canceled?).to eq false
      end

      context '不正なTAX ID' do
        it 'contractor_not_found のエラーが返ること' do
          params = default_params.dup
          params[:tax_id] = 'aaa'

          post rudy_cancel_order_path, params: params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "contractor_not_found"
          expect(order.reload.canceled?).to eq false
        end
      end

      context '不正なDealer Code' do
        it 'contractor_not_found のエラーが返ること' do
          params = default_params.dup
          params[:dealer_code] = 'aaa'

          post rudy_cancel_order_path, params: params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "dealer_not_found"
          expect(order.reload.canceled?).to eq false
        end
      end

      context '不正なOrder Number' do
        it 'order_not_found のエラーが返ること' do
          params = default_params.dup
          params[:order_number] = 'aaa'

          post rudy_cancel_order_path, params: params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "order_not_found"
          expect(order.reload.canceled?).to eq false
        end
      end

      context 'キャンセル済み' do
        before do
          order.update!(canceled_at: Time.now)
        end

        it 'already_canceled_order のエラーが返ること' do
          post rudy_cancel_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "already_canceled_order"
          expect(order.reload.canceled?).to eq true
        end
      end

      context 'Switch申請中' do
        before do
          order.update!(is_applying_change_product: true)
        end

        it 'switched_order のエラーが返ること' do
          post rudy_cancel_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "switched_order"
          expect(order.reload.canceled?).to eq false
        end
      end

      context 'リスケしたオーダー' do
        before do
          order.update!(rescheduled_new_order_id: 1)
        end

        it 'rescheduled_order のエラーが返ること' do
          post rudy_cancel_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "rescheduled_order"
          expect(order.reload.canceled?).to eq false
        end
      end

      context 'リスケで作成されたオーダー' do
        before do
          order.update!(rescheduled_at: Time.now)
        end

        it 'reschedule_order のエラーが返ること' do
          post rudy_cancel_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "reschedule_order"
          expect(order.reload.canceled?).to eq false
        end
      end
    end
  end
end
