desc 'PDF作成時にサポートされていないQRコードの画像を持つContractorを見つける'
task find_unsupported_qr_image: :environment do |task, args|
  pdf = Prawn::Document.new
  error_count = 0

  Contractor.all.each do |contractor|
    if contractor.qr_code_image.attached?
      begin
        # 画像のダウンロード
        qr_image = StringIO.new(contractor.qr_code_image.download)
        # PDFへ画像の挿入
        pdf.image qr_image
      rescue => e
        p "ContractorID: #{contractor.id}. Error: #{e.inspect}"
        error_count += 1
      end
    end
  end

  p "合計エラー: #{error_count}件"
end

def error_msg
  p "!!! エラー !!!"
end