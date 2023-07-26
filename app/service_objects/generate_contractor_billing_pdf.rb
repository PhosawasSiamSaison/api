class GenerateContractorBillingPDF
  def call(contractor_billing_data)
    @dev_mode = false

    margin = 15

    pdf = Prawn::Document.new(
      page_size: 'A4',
      margin: margin
    )

    set_font(pdf)

    pdf.stroke_axis if @dev_mode

    # PDFフォーマットでPDFを分ける
    contractor_billing_data.generate_pdf_list.each_with_index do |row, i|
      pdf.start_new_page if i > 0

      render_pdf(pdf, row[:format_type], contractor_billing_data, row[:list])
    end

    file_name = "#{contractor_billing_data.ref}.pdf"

    return [pdf, file_name]
  end

  def render_pdf(pdf, format_type, contractor_billing_data, installment_list)
    # PDFのページ数を計算
    per_page = 10
    page_count = (installment_list.count + 9) / per_page

    # installmentsのid
    installment_index = 0

    # installmentが11件以上の場合は複数ページになる
    # ページ分の描写を繰り返す
    page_count.times do |i|
      # 2ページ目以降は改ページをいれる
      pdf.start_new_page if i > 0

      # 初期フォントサイズ
      pdf.font_size font_size(16)

      # 左上のロゴ
      pdf.image 'public/pdf/saison_logo.png', at: [0, 820], width: 80

      # 右上のsaison情報
      pdf.bounding_box([270, 800], :width => 300, :height => 100) do
        pdf.stroke_bounds if @dev_mode

        pdf.font_size font_size(16)
        pdf.text "ใบแจ้งยอดรายการเซย์ซอนเครดิต/ใบแจ้งหนี้", align: :right

        pdf.image 'public/pdf/saison_logo2.png', position: :center, width: 80
        pdf.move_down 5

        pdf.font_size font_size(11)
        pdf.text "บริษัท สยาม เซย์ซอน จำกัด", align: :right

        pdf.text "เลขที่ 1 ถนนปูนซิเมนต์ไทย บางซื่อ กรุงเทพฯ 10800", align: :right

        pdf.text "โทรศัพท์ 02-586-3021", align: :right

        pdf.font_size font_size(9)
        pdf.text "เวลาทำการ จันทร์ - ศุกร์ 09.00 - 17.00 ยกเว้นวันหยุดนักขัตฤกษ์", align: :right
      end

      # Ref
      pdf.font_size font_size(7)
      pdf.draw_text "Ref:         #{contractor_billing_data.ref}", :at => [0, 750]
      pdf.move_down 5

      # Contractor情報
      pdf.bounding_box([0, 720], :width => 300, :height => 70) do
        pdf.stroke_bounds if @dev_mode

        # Line Heightの設定
        leading = 3

        # Th Company Name
        pdf.font_size font_size(10)
        pdf.text "เรียน    #{contractor_billing_data.th_company_name}", leading: leading

        # Address
        pdf.text contractor_billing_data.address, leading: leading

        # Tax ID
        pdf.text "เลขทะเบียนนิติบุคคล     #{contractor_billing_data.tax_id}", leading: leading
      end

      # 太線で囲んだエリア
      pdf.bounding_box([0, 640], width: 550, height: 100) do
        pdf.stroke_bounds if @dev_mode

        pdf.line_width = 4
        pdf.line([0, pdf.bounds.height], [pdf.bounds.width, pdf.bounds.height])
        pdf.stroke
        pdf.line_width = 1

        padding_left = 50
        pdf.bounding_box([padding_left, 100], width: pdf.bounds.width - (padding_left * 2), height: pdf.bounds.height / 2) do
          pdf.stroke_bounds if @dev_mode

          # 左側の項目
          pdf.bounding_box([0, pdf.bounds.height], width: 100, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.move_down 10
            pdf.text "วงเงินทั้งหมด"

            pdf.move_down 5
            pdf.text "วงเงินคงเหลือ"
          end

          # 金額
          pdf.bounding_box([240, pdf.bounds.height], width: 150, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.move_down 10
            pdf.text "#{currency(contractor_billing_data.credit_limit)}", align: :right

            pdf.move_down 5
            pdf.text "#{currency(contractor_billing_data.available_balance)}", align: :right
          end

          # 単位
          pdf.bounding_box([420, pdf.bounds.height], width: 50, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.move_down 10
            pdf.text "บาท"

            pdf.move_down 5
            pdf.text "บาท"
          end
        end

        pdf.line([0, 50], [pdf.bounds.width, 50])
        pdf.stroke

        pdf.move_down 6
        pdf.text "ท่านสามารถตรวจสอบรายละเอียดวงเงินและประวัติการทำรายการของท่านได้ที่ ssc.siamsaison.com", align: :center

        pdf.line_width = 4
        pdf.line([0, 30], [pdf.bounds.width, 30])
        pdf.stroke
        pdf.line_width = 1

        # 太線の下段 左
        pdf.bounding_box([5, 18], width: (pdf.bounds.width / 2), height: 18) do
          pdf.stroke_bounds if @dev_mode

          pdf.text "ยอดชำระที่ครบกำหนดชำระ"

          pdf.bounding_box([100, pdf.bounds.height], width: 150, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode
            pdf.text "#{currency(due_amount(installment_list))}  บาท", align: :right
          end
        end

        pdf.line([pdf.bounds.width / 2, 0], [pdf.bounds.width / 2, 30])
        pdf.stroke

        # 太線の下段 右
        pdf.bounding_box([(pdf.bounds.width / 2) + 10, 18], width: (pdf.bounds.width / 2), height: 18) do
          pdf.stroke_bounds if @dev_mode

          pdf.text "วันครบกำหนดชำระเงิน"

          pdf.bounding_box(
            [pdf.bounds.width / 2, pdf.bounds.height],
            width: (pdf.bounds.width / 2) - 25,
            height: pdf.bounds.height
          ) do
            pdf.stroke_bounds if @dev_mode

            pdf.text "#{th_date(contractor_billing_data.due_ymd)}", align: :right
          end
        end

        pdf.line_width = 4
        pdf.line([0, 0], [pdf.bounds.width, 0])
        pdf.stroke
        pdf.line_width = 1
      end

      # Cut-Off Date
      pdf.bounding_box([5, 530], width: 550, height: 40) do
        pdf.stroke_bounds if @dev_mode

        pdf.font_size font_size(14)
        pdf.text "รายละเอียดรายการครบกำหนดชำระ"
        pdf.font_size font_size(10)

        pdf.move_down 5
        pdf.text "ยอดเงินถึงวันที่          #{th_date(contractor_billing_data.cut_off_ymd)}"
      end

      # Installments 一覧
      pdf.bounding_box([0, 470], width: pdf.bounds.width, height: 240) do
        pdf.stroke_bounds if @dev_mode

        # 各ページでのinstallmentの要素を取得する
        installment_list_per_page = installment_list[(i * 10)..(i * 10 + 9)]

        # テーブルデータ
        table_data = []

        # ヘッダー
        table_header_data = []
        table_header_data.push('รายการที่') # index
        table_header_data.push('ชื่อผู้แทนจำหน่าย') # dealer_name
        table_header_data.push('หน่วยงาน') if format_type == :cps # site_name
        table_header_data.push('ประเภท') if format_type == :cps # order_type
        table_header_data.push('เลขที่รายการ') # order_number
        # input_ymd
        if format_type == :sss
          table_header_data.push('วันนำเข้าข้อมูล (โดยผู้แทนจำหน่าย)')
        elsif format_type == :cps
          table_header_data.push('วันนำเข้าข้อมูล')
        else
          raise
        end
        table_header_data.push('ยอด') # amount
        table_header_data.push('งวด') # installment round

        table_data.push(table_header_data)

        # installmentのデータ
        per_page.times do |i|
          data = installment_list_per_page[i]
          installment_index += 1

          if data
            # 回数の表示
            installment_round = "(#{data['installment_number']}/#{data['installment_count']})"

            table_body_data = []
            table_body_data.push(installment_index)
            table_body_data.push(data.fetch('dealer_name') || '-')
            table_body_data.push(data.fetch('site_name')) if format_type == :cps
            table_body_data.push(data.fetch('order_type')) if format_type == :cps
            table_body_data.push(data.fetch('order_number'))
            table_body_data.push(th_date(data.fetch('input_ymd')))
            table_body_data.push(currency(data.fetch('total_amount')))
            table_body_data.push(installment_round)

            table_data.push(table_body_data)
          else
            # データがなくても10件分の行を描写する
            table_data.push(Array.new(table_header_data.count, ''))
          end
        end

        pdf.table(
          table_data,
          header: true,
          width: pdf.bounds.width,
          #column_widths: {0 => 50, 1 => 80, 5 => 150},
          cell_style: { height: 20, :overflow => :shrink_to_fit }
        ) do |t|
          t.cells.borders = [] unless @dev_mode

          if format_type == :sss
            t.columns(0).style :align => :center # index
            t.columns(1).style :align => :left # dealer_name
            t.columns(2).style :align => :left # order_number
            t.columns(3).style :align => :center # input_ymd
            t.columns(4).style :align => :right # amount
            t.columns(5).style :align => :center # installment_round
          else # cpac
            t.columns(0).style :align => :center # index
            t.columns(1).style :align => :left # dealer_name
            t.columns(2).style :align => :left # site_name
            t.columns(3).style :align => :left # order_type
            t.columns(4).style :align => :left # order_number
            t.columns(5).style :align => :center # input_ymd
            t.columns(6).style :align => :right # amount
            t.columns(7).style :align => :center # installment_round
          end

          t.row(0).borders = [:bottom]
          # columns.styleの後に設定する
          t.row(0).style :align => :center#, height: 33
        end

        # リスト下部の合計金額
        pdf.bounding_box([250, 12], width: pdf.bounds.width / 2, height: 15) do
          pdf.stroke_color "bd0729"
          pdf.stroke_bounds if @dev_mode
          pdf.stroke_color "000000"

          pdf.text "ยอดรวมครบกำหนดชำระ"

          pdf.bounding_box([pdf.bounds.width / 2, pdf.bounds.height], width: pdf.bounds.width / 2, height: pdf.bounds.height) do
            pdf.text "#{currency(due_amount(installment_list))}    บาท", align: :right
          end
        end
      end

      # 下部の支払い欄
      pdf.bounding_box([0, 225], width: pdf.bounds.width, height: 200) do
        pdf.stroke_bounds if @dev_mode

        # 赤い線
        pdf.line_width = 16
        pdf.stroke_color "bd0729"
        pdf.line([0, pdf.cursor - (pdf.line_width / 2)], [pdf.bounds.width, pdf.cursor - (pdf.line_width / 2)])
        pdf.stroke
        pdf.stroke_color "000000"

        pdf.move_down 3
        pdf.text 'ช่องทางการชำระเงิน และการนำส่งหลักฐานการชำระเงิน', align: :center, color: 'ffffff'

        padding_top = pdf.bounds.height - 25

        # 左側の銀行情報
        pdf.bounding_box([10, padding_top], width: 220, height: 70) do
          pdf.line_width = 1
          pdf.stroke_bounds if @dev_mode

          # Line Heightの設定
          leading = 3

          col_w = 80
          pdf.bounding_box([0, pdf.bounds.height], width: col_w, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.text 'ธนาคาร', leading: leading
            pdf.text 'ชื่อบัญชี', leading: leading
            pdf.text 'เลขที่บัญชี', leading: leading
            pdf.text 'ประเภทบัญชี', leading: leading
          end

          row_w = pdf.bounds.width - col_w
          pdf.bounding_box([col_w, pdf.bounds.height], width: row_w, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.text 'ไทยพาณิชย์ จำกัด (มหาชน)', leading: leading
            pdf.text 'บริษัท สยาม เซย์ซอน จำกัด', leading: leading
            pdf.text '111-3-93830-0', leading: leading
            pdf.text 'กระแสรายวัน', leading: leading
          end
        end

        # 左側のQR欄
        pdf.bounding_box([10, pdf.bounds.height - 100], width: 200, height: 95) do
          pdf.stroke_bounds if @dev_mode

          col_w = 100
          pdf.bounding_box([0, pdf.bounds.height], width: col_w, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            pdf.move_down 30
            pdf.text 'QR Code'
            pdf.move_down 5
            pdf.text 'สำหรับโอนเงิน'
          end

          row_w = pdf.bounds.width - col_w
          pdf.bounding_box([col_w, pdf.bounds.height], width: row_w, height: pdf.bounds.height) do
            pdf.stroke_bounds if @dev_mode

            # QRコードの貼り付け
            contractor = contractor_billing_data.contractor
            image_error = false
            qr_image = nil

            # QR画像の取得
            begin
              if contractor.qr_code_image.attached?
                qr_image = StringIO.new(contractor.qr_code_image.download)

                pdf.image qr_image, at: [0, pdf.bounds.height], width: pdf.bounds.height - 5
              end
            rescue => e
              image_error = true
              Rails.logger.info("ContractorID: #{contractor.id}")
              Rails.logger.info e.inspect
            end

            if qr_image.blank? || image_error
              pdf.draw_text "no image", at: [0, pdf.bounds.height / 2]
            end
          end
        end

        # 右側
        pdf.bounding_box([270, padding_top], width: 250, height: 140) do
          pdf.stroke_bounds if @dev_mode

          # 行間の設定
          leading = 5

          pdf.text 'กรุณาอัพโหลดนำส่งหลักฐานการชำระเงินมาที่', leading: leading

          pdf.font_size font_size(9)
          pdf.text 'ssc.siamsaison.com'
          pdf.move_down 5

          pdf.text '- ใส่ชื่อผู้ใช้งานและรหัสผ่านของท่าน', leading: leading
          pdf.move_down 3

          pdf.bounding_box([0, pdf.cursor + 3], width: pdf.bounds.width, height: 15) do
            pdf.stroke_bounds if @dev_mode
            pdf.text '- กด'
            pdf.image 'public/pdf/add_icon.png', at: [25, pdf.bounds.height], width: 30
          end
          pdf.move_down 3

          pdf.bounding_box([0, pdf.cursor + 2], width: pdf.bounds.width, height: 15) do
            pdf.stroke_bounds if @dev_mode
            pdf.text '- เลือกแนบไฟล์           เพื่ออัพโหลดหลักฐาน'
            pdf.image 'public/pdf/upload_icon.png', at: [65, pdf.bounds.height + 1], width: 15
          end
          pdf.move_down 3

          pdf.text '- เลือกบันทึกเพื่อทำการนำส่งหลักฐาน', leading: leading
        end
      end

      # フッター
      h = 20
      pdf.bounding_box([0, h], width: pdf.bounds.width, height: h) do
        pdf.stroke_bounds if @dev_mode

        pdf.line([0, pdf.bounds.height], [pdf.bounds.width, pdf.bounds.height])
        pdf.stroke

        pdf.move_down 4
        pdf.text 'กรุณาชำระภายในกำหนดเพื่อหลีกเลี่ยงเบี้ยปรับชำระล่าช้า', align: :center

        pdf.line_width = 4
        pdf.line([0, 0], [pdf.bounds.width, 0])
        pdf.stroke
        pdf.line_width = 1
      end
    end
  end

  def set_font(pdf)
    # フォントの設定

    # 崩れる
    pdf.font_families.update("Taviraj" => {
      normal: "public/pdf/Taviraj/Taviraj-Regular.ttf"
    })

    # TH Fahkwang
    pdf.font_families.update("TH-Fahkwang" => {
      normal: "public/pdf/TH-Fahkwang.ttf"
    })

    pdf.font "TH-Fahkwang"
  end

  def font_size(size)
    (size * 1.2).round(1)
  end

  def due_amount(installment_list)
    installment_list.sum do |installment_data|
      installment_data['total_amount']
    end
  end

  def th_date(ymd)
    BusinessDay.th_month_format_date(ymd, short_month: true)
  end

  def currency(amont)
    amont.to_s(:currency, unit: '', precision: 2)
  end
end
