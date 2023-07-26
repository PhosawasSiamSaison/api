# frozen_string_literal: true

class Jv::ProductListController < ApplicationController
  before_action :auth_user
  
  def search
    products = Product.all.number_sort.map do |product|
      {
        id: product.id,
        product_key:            product.product_key,
        product_name:           product.product_name,
        number_of_installments: product.number_of_installments,
        annual_interest_rate:   product.annual_interest_rate.to_f,
        monthly_interest_rate:  product.monthly_interest_rate.to_f,
      }
    end

    render json: { success: true, products: products }
  end

end
