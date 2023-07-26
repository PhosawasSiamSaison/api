class ChangeColumns < ActiveRecord::Migration[5.2]
  def change
    # 複製したデータのカラムから制約を外す
    change_column :contractor_billing_data, :th_company_name, :string, null: true
    change_column :contractor_billing_data, :address,         :string, null: true

    change_column :receive_amount_details, :th_company_name,  :string, null: true
    change_column :receive_amount_details, :en_company_name,  :string, null: true
  end
end
