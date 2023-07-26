class AddNeedColumnsToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :approved_at, :datetime, comment: '審査許可日', after: :contact_person_personal_id
    add_column :contractors, :create_user_id, :integer, comment: 'データ作成者', after: :created_at
    add_column :contractors, :register_user_id, :integer, comment: '本登録ユーザ', after: :registered_at
    add_column :contractors, :rejected_at, :datetime, comment: '審査不許可日', after: :deleted
    add_column :contractors, :reject_user_id, :integer, comment: '審査不許可ユーザ', after: :rejected_at
  end
end
