class AddColumnToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :sort_number, :integer, limit: 1, after: :number_of_installments

    Product.reset_column_information
    Product.find_by(product_key: 1)&.update!(sort_number: 1)
    Product.find_by(product_key: 4)&.update!(sort_number: 2)
    Product.find_by(product_key: 2)&.update!(sort_number: 3)
    Product.find_by(product_key: 3)&.update!(sort_number: 4)
  end
end
