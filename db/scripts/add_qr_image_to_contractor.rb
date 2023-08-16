qr_file_names = Dir.entries("C:/Users/PhosawasPinitchai/Downloads/qr_image").reject { |name| name == '.' || name == '..'}
puts "all file is #{qr_file_names.count}"
ActiveRecord::Base.transaction do
  qr_file_names.each do |name|
    file_id_str = name[/[0-9][0-9][0-9][0-9]/]
    qr_file_image = File.open("C:/Users/PhosawasPinitchai/Downloads/qr_image/#{name}")
    contractor = Contractor.find_by(id: file_id_str.to_i)
    if contractor 
      contractor.qr_code_image.attach(io: qr_file_image, filename: name)
      contractor.update!(qr_code_updated_at: Time.zone.now)
    else 
      puts "contractor id #{file_id_str.to_i} not found"
    end
  end
end
