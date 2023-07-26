class AddNotesUpdateColumnsToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :notes_updated_at, :datetime, after: :notes, comment: 'Notes更新日'
    add_column :contractors, :notes_update_user_id, :integer, after: :notes_updated_at, comment: 'Notes更新ユーザID'
  end
end