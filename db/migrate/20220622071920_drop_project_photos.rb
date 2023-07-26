class DropProjectPhotos < ActiveRecord::Migration[5.2]
  def change
    drop_table :project_photos
  end
end
