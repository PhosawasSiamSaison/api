class CreateAndUploadContractorBillingZip
  require 'zip'

  def call(due_ymd)
    # 請求データからPDFを生成
    pdf_list = ContractorBillingData.where(due_ymd: due_ymd).map do |contractor_billing_data|
      pdf, file_name = GenerateContractorBillingPDF.new.call(contractor_billing_data)

      {
        pdf: pdf,
        tax_id: contractor_billing_data.contractor.tax_id,
        file_name: file_name,
      }
    end

    return if pdf_list.blank?

    zip_output_dir    = "tmp"
    zip_dir_name      = "contractor-billing_#{due_ymd}"
    zip_file_name     = "contractor-billing_#{due_ymd}.zip"
    zip_path          = File.join(zip_output_dir, zip_file_name)
    tmp_pdfs_dir_path = File.join(zip_output_dir, zip_dir_name)

    # PDFの一時ディレクトリを作成
    Dir.mkdir(tmp_pdfs_dir_path) unless Dir.exist?(tmp_pdfs_dir_path)

    # 削除用にPDFのパスを入れる変数
    pds_paths = []

    Zip::OutputStream.open(zip_path) do |out|
      pdf_list.each do |pdf_data|
        pdf           = pdf_data[:pdf]
        tax_id        = pdf_data[:tax_id]
        pdf_file_name = pdf_data[:file_name]

        # pdfの保存
        pdf_path = File.join(tmp_pdfs_dir_path, pdf_file_name)
        pdf.render_file(pdf_path)

        # 削除用にパスを保持する
        pds_paths.push(pdf_path)

        # 展開後のzipのディレクトリ名とPDFのファイル名
        out.put_next_entry(File.join(zip_dir_name, pdf_file_name))

        buffer = File.read(pdf_path)
        out.write(buffer)
      end
    end

    # active_storageと紐付ける用のレコードを作成する
    contractor_billing_zip_ymd =
      ContractorBillingZipYmd.create!(due_ymd: due_ymd)

    # AWSへアップロード
    contractor_billing_zip_ymd.zip_file.attach(
      io: File.open(zip_path),
      filename: "#{due_ymd}.zip",
      content_type: "application/zip"
    )

    # 一時ファイルを削除する
    pds_paths.each do |pdf_path|
      File.delete(pdf_path) if File.exist?(pdf_path)
    end

    Dir.rmdir(tmp_pdfs_dir_path) if Dir.exist?(tmp_pdfs_dir_path)

    File.delete(zip_path) if File.exist?(zip_path)
  end
end
