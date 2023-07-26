# == Schema Information
#
# Table name: global_available_settings
#
#  id                   :bigint(8)        not null, primary key
#  contractor_type      :integer          not null
#  category             :integer          not null
#  dealer_type          :integer          not null
#  product_id           :bigint(8)        not null
#  available            :boolean          not null
#  create_user_id       :bigint(8)
#  update_user_id       :bigint(8)
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class GlobalAvailableSetting < ApplicationRecord
  belongs_to :product

  class << self
    def format_global_available_settings(contractor_type)
      contractor_type_data = GlobalAvailableSetting.where(contractor_type: contractor_type)

      products = Product.all

      result = {}

      ApplicationRecord.categories.keys.each {|category|
        category = category.to_sym
        result[category] = {}

        # categoryで絞る
        category_data = contractor_type_data.select {|row| row["category"] == category.to_s}

        ApplicationRecord.dealer_types.keys.each {|dealer_type|
          dealer_type = dealer_type.to_sym
          result[category][dealer_type] = {}

          if category != :cashback
            dealer_type_data = category_data.select {|row| row["dealer_type"] == dealer_type.to_s}

            products.each {|product|

              product_data = dealer_type_data.find {|row| row["product_id"] == product.id}

              result[category][dealer_type][product.product_key] = product_data["available"]
            }
          else
            dealer_type_data = category_data.find {|row| row["dealer_type"] == dealer_type.to_s}

            result[category][dealer_type] = dealer_type_data["available"]
          end
        }
      }

      result
    end

    def insert_category_data(insert_data)
      transaction do
        products = Product.all

        insert_data.each {|contractor_type, category_data|

          category_data.each {|category, dealer_type_data|

            if category != :cashback

              dealer_type_data.each {|dealer_type, product_data|

                product_data.each {|product_key, is_available|
                  create!(
                    contractor_type: contractor_type,
                    category: category,
                    dealer_type: dealer_type,
                    product_id: products.find_by(product_key: product_key).id,
                    available: is_available,
                  )
                }
              }
            else

              dealer_type_data.each {|dealer_type, is_available|
                create!(
                  contractor_type: contractor_type,
                  category: category,
                  dealer_type: dealer_type,
                  product_id: products.find_by(product_key: 1).id,
                  available: is_available,
                )
              }
            end
          }
        }
      end
    end
  end
end
