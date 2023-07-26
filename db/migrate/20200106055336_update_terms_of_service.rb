class UpdateTermsOfService < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :terms_of_service_version, :integer, default: 1, after: :id
    add_column :contractor_users, :terms_of_service_version, :integer, after: :agreed_at

    ContractorUser.reset_column_information
    # 規約同意済みコントラクターの規約同意バージョンに1をセット
    ContractorUser.where.not(agreed_at: nil).update_all(terms_of_service_version: 1)
  end
end
