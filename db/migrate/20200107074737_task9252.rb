class Task9252 < ActiveRecord::Migration[5.2]
  def change
    add_column :active_storage_attachments, :operation_updated_at, :datetime, null: true, after: :created_at
    add_column :active_storage_blobs, :operation_updated_at, :datetime, null: true, after: :created_at
    add_column :areas, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :auth_tokens, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :business_days, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :cashback_histories, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :change_product_applies, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :contractor_users, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :contractors, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :contractors_unavailable_products, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :dealer_purchase_of_months, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :dealer_users, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :dealers, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :eligibilities, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :evidences, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :exemption_late_charges, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :for_dealer_payments, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :installment_histories, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :installments, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :jv_users, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :orders, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :payments, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :products, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :receive_amount_histories, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :rudy_api_settings, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :scoring_assets, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :scoring_comments, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :scoring_files, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :scoring_results, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :sms_spools, :operation_updated_at, :datetime, null: true, after: :updated_at
    add_column :system_settings, :operation_updated_at, :datetime, null: true, after: :updated_at
  end
end
