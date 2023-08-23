# frozen_string_literal: true
# == Schema Information
#
# Table name: contractor_billing_data
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  th_company_name      :string(255)
#  address              :string(255)
#  tax_id               :string(13)       not null
#  due_ymd              :string(8)        not null
#  credit_limit         :decimal(13, 2)
#  available_balance    :decimal(13, 2)
#  due_amount           :decimal(13, 2)
#  cut_off_ymd          :string(8)        not null
#  installments_json    :text(65535)
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#

class ContractorBillingData < ApplicationRecord
  belongs_to :contractor

  validates :due_ymd, uniqueness: { scope: :contractor_id, case_sensitive: false }

  class << self
    def search(params)
      relation = eager_load(:contractor, contractor: :applied_dealers)
        .order(due_ymd: :desc).order(:contractor_id)
      # dealer検索用に最新のapplied_dealersを取得する

      # Date
      if params.dig(:search, :due_ymd).present?
        due_ymd  = params.dig(:search, :due_ymd)
        relation = relation.where(due_ymd: due_ymd)
      end

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
      end

      # Company Name(en_company_name, th_company_name)
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)

        relation = relation.where(
          "CONCAT(contractors.en_company_name, contractors.th_company_name) LIKE ?",
          "%#{company_name}%"
        )
      end

      # Use Only Credit Limit
      if params.dig(:search, :use_only_credit_limit).to_s == 'true'
        relation = relation.where("contractors.use_only_credit_limit = ?", true)
      end

      # Dealer
      if params.dig(:search, :dealer_id).present?
        dealer_id = params.dig(:search, :dealer_id)
        relation = relation.where(contractors: {applied_dealers: {dealer_id: dealer_id}})
      end

      # Dealer Type
      if params.dig(:search, :dealer_type).present?
        dealer_type = params.dig(:search, :dealer_type)
        relation = relation.includes(contractor: {eligibilities: :dealer_type_limits})
          .where(contractors: {eligibilities: {latest: true, dealer_type_limits: {dealer_type: dealer_type}}})
      end
      
      # paging
      total_count = relation.count
      result      = paginate(params[:page], relation, params[:per_page])

      [result, total_count]
    end

    # 請求PDF & Zipの用のデータの保存
    def create_by_payment(payment, cut_off_ymd)
      billing_data = find_by(contractor: payment.contractor, due_ymd: payment.due_ymd)

      if billing_data.present?
        # เมื่อเพิ่มผลิตภัณฑ์ที่ 15 ในการชำระเงินที่มีอยู่
        if payment.has_15day_products?
          # ลบเพื่อสร้างใหม่
          billing_data.delete
        else
          # หากไม่มีสินค้าภายใน 15 วัน จะไม่สามารถดำเนินการได้
          return
        end
      end

      # installmentsを整形する
      formatted_installments = payment.installments.map do |installment|
        order = installment.order

        {
          dealer_type: order.dealer&.dealer_type_before_type_cast,
          dealer_name: order.dealer&.dealer_name,
          site_name: order.site&.site_name,
          order_type: order.order_type,
          order_number: order.order_number,
          input_ymd: order.input_ymd,
          total_amount: installment.total_amount,
          installment_number: installment.installment_number,
          installment_count: order.installment_count,
          is_rescheduled: order.rescheduled_new_order?,
        }
      end

      contractor = payment.contractor

      create!(
        contractor: contractor,
        th_company_name: contractor.th_company_name,
        address: contractor.address,
        tax_id: contractor.tax_id,
        cut_off_ymd: cut_off_ymd,
        due_ymd: payment.due_ymd,
        credit_limit: contractor.credit_limit_amount,
        available_balance: contractor.available_balance,
        due_amount: payment.total_amount,
        installments_json: formatted_installments.to_json
      )
    end
  end

  def ref
    # 接頭辞
    # 両方あれば接頭辞はなし
    prefix =
      if generate_pdf_list.count == 2
        ''
      elsif generate_pdf_list.find{|row| row[:format_type] == :sss}
        'SSS'
      else
        'CPS'
      end

    "#{prefix}#{cut_off_ymd}#{format('%04d', contractor_id)}"
  end

  # DealerTypeからPDFフォーマット毎にinstallment_dataを分ける
  def generate_pdf_list
    return @list if @list

    installments_hash = split_installments_by_dealer_type

    sss_installment_list = installments_hash.find{|key, _| key == :sss}[1]
    cps_installment_list = installments_hash.find{|key, _| key == :cps}[1]

    list = []
    list.push({ format_type: :sss, list: sss_installment_list }) if sss_installment_list.present?
    list.push({ format_type: :cps, list: cps_installment_list }) if cps_installment_list.present?

    @list = list

    return list
  end

  private

  def split_installments_by_dealer_type
    # PDFのフォーマット
    installments_hash = {
      sss: [],
      cps: [],
    }

    JSON.parse(installments_json).each do |installment_data|
      # dealer_typeフォーマットを取得
      dealer_type_format = pdf_dealer_type_format(installment_data)

      # dealer_typeに対応するキーにデータを追加する
      installments_hash[dealer_type_format.to_sym].push(installment_data)
    end

    installments_hash
  end

  def pdf_dealer_type_format(installment_data)
    # 再約定はSSSフォーマット
    return :sss if installment_data['is_rescheduled']

    # dealer_typeの数値をシンボルへ
    dealer_type = convert_dealer_type_by_raw_value(installment_data['dealer_type'])

    if dealer_type_setting(dealer_type).cbm_group? || dealer_type_setting(dealer_type).project_group?
      return :sss
    elsif dealer_type_setting(dealer_type).cpac_group?
      return :cps
    else
      raise "unexpected dealer_type: #{dealer_type}"
    end
  end

  # dealer_typeの数値をシンボルのdealer_nameへ変換
  def convert_dealer_type_by_raw_value(num)
    ApplicationRecord.dealer_types.find{|_, v| v == num}[0].to_sym
  end

  def dealer_type_setting(dealer_type)
    DealerTypeSetting.find_by(dealer_type: dealer_type)
  end
end
