# frozen_string_literal: true

module TestFile
  # サンプル画像
  def sample_image_data_uri
    original_image = Rack::Test::UploadedFile.new("spec/fixtures/image/test.jpeg", "image/jpeg")
    base64_image   = Base64.urlsafe_encode64(original_image.read)
    "data:image/*;base64,#{base64_image}"
  end
end
