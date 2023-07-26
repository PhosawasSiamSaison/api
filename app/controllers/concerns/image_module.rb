module ImageModule
  def parse_base64(image)
    base64_image  = image.sub(/^data:.*,/, '')
    decoded_image = Base64.urlsafe_decode64(base64_image)
    StringIO.new(decoded_image)
  end
end