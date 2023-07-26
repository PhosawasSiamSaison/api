class AddQrCodeUploadedAtToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :qr_code_updated_at, :datetime, after: :updated_at
  end
end
