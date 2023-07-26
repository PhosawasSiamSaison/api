# frozen_string_literal: true

class Rudy::GetInstallmentInfoController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    tax_id = params[:tax_id]
    dealer_code = params[:dealer_code]
    amount = params[:amount].to_f

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'dealer_not_found') if dealer.blank?

    # DealerがDealerLimitで設定されているかをチェック
    dealer_limit_enabled = contractor.latest_dealer_limits.exists?(dealer: dealer)

    if dealer_limit_enabled || contractor.use_only_credit_limit
      all_product_keys =
        contractor.available_settings[:purchase][:dealer_type][dealer.dealer_type.to_sym][:product_key]

      available_product_keys = all_product_keys.select{|product_key, value| value[:available]}.keys

      # 表示する商品を取得
      products = Product.where(product_key: available_product_keys)
    else
      # DealerLimitが未設定なら商品リストは返さない
      products = Product.none
    end

    render json: {
      result: "OK",
      products: products.number_sort.map { |product|
        {
          product_id:             product.product_key,
          product_name:           product.product_name,
          number_of_installments: product.number_of_installments,
          annual_interest_rate:   (dealer.interest_rate || product.annual_interest_rate).to_f,
          monthly_interest_rate:  product.monthly_interest_rate.to_f,
          total_amount:           product.total_amount(amount, dealer.interest_rate),
          installment_amount:     product.installment_amount(amount, dealer.interest_rate),
          installment_amounts:    product.rudy_install_amounts(amount, dealer.interest_rate),
        }
      }
    }
  end

  private
  def render_demo_response
    tax_id = params[:tax_id]
    dealer_code = params[:dealer_code]
    amount = params[:amount]

    # Success
    if tax_id == '1234567890111' && dealer_code == '1234'
      return render json: { result: "OK", products: sample_products }
    end

    # Error : contractor_not_found
    raise(ValidationError, 'contractor_not_found') if tax_id == '1234567890000' && dealer_code == '1234'

    # Error : dealer_not_found
    raise(ValidationError, 'dealer_not_found') if tax_id == '1234567890111' && dealer_code == '0000'

    # 一致しない
    raise NoCaseDemo
  end

  def sample_products
    [
      {
        product_id: 1,
        product_name: "Product 1",
        number_of_installments: 1,
        annual_interest_rate: 0.0,
        monthly_interest_rate: 0.0,
        total_amount: 1000000.0,
        installment_amount: 1000000.0,
        installment_amounts: [
          1000000.0
        ]
      },
      {
        product_id: 2,
        product_name: "Product 2",
        number_of_installments: 3,
        annual_interest_rate: 2.51,
        monthly_interest_rate: 0.83,
        total_amount: 1025100.0,
        installment_amount: 341699.99,
        installment_amounts: [
          341700.02,
          341699.99,
          341699.99
        ]
      },
      {
        product_id: 3,
        product_name: "Product 3",
        number_of_installments: 6,
        annual_interest_rate: 4.42,
        monthly_interest_rate: 0.73,
        total_amount: 1044200.0,
        installment_amount: 174033.32,
        installment_amounts: [
          174033.4,
          174033.32,
          174033.32,
          174033.32,
          174033.32,
          174033.32
        ]
      },
      {
        product_id: 4,
        product_name: "Product 4",
        number_of_installments: 1,
        annual_interest_rate: 15.0,
        monthly_interest_rate: 0.0,
        total_amount: 1150000.0,
        installment_amount: 1150000.0,
        installment_amounts: [
          1150000.0
        ]
      },
    ]
  end
end
