# frozen_string_literal: true

# SMS: 11, 15 の本文に挿入するSwitchに関するデータの取得
class SwitchMessageBodyData
  def call(payment)
    data_array = []

    payment.can_apply_change_product_orders.each do |order|
      contractor = order.contractor
      dealer = order.dealer
      dealer_type = dealer.dealer_type

      # 既存のデータを見つける
      data = data_array.find{|data| data[:dealer_type] == dealer_type}

      # ない場合はデータを作成する
      if data.blank?
        # productから本文に挿入するswitch可能な商品名(switch_sms_product_name)を取得する
        switch_sms_product_names = contractor.allowed_change_products(dealer_type).map do |product|
          product.switch_sms_product_name
        end

        line_account = contractor.sub_dealer? ?
          SmsSpool::SUB_DEALER_LINE_ACCOUNT : dealer.dealer_type_setting.sms_line_account

        data = {
          dealer_type: dealer_type,
          total_due_amount: order.purchase_amount,
          switch_sms_product_names: switch_sms_product_names,
          line_account: line_account
        }

        data_array.push(data)
      else
        # Orderの合計金額を加算する
        data[:total_due_amount] = (data[:total_due_amount] + order.purchase_amount).round(2).to_f
      end
    end

    data_array
  end
end
