class AddColumnProjectDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :project_documents, :ss_staff_only, :boolean, after: :file_type, default: false
  end
end
