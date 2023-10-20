# frozen_string_literal: true

module CsvModule
  require 'csv'

  # Oder List CSV
  def send_order_list_csv(orders)
    data = order_list_data(orders)
    filename = "sss-order-list_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Daily Received Amount History CSV
  def send_daily_received_amount_history_csv(histories)
    data = daily_received_amount_history_data(histories)
    filename = "sss-daily_received_amount_history_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Due Basis
  def send_due_basis_csv
    data = due_basis_data()
    filename = "sss-due_basis_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Order Basis
  def send_order_basis_csv
    # ボディ行
    data = order_basis_data()
    filename = "sss-order_basis_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Site List
  def send_site_list_csv
    # ボディ行
    data = site_list_data()
    filename = "sss-site_list_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Reschedule CSV
  def send_reschedule_csv(*args)
    data = reschedule_data(*args)
    filename = "sss-reschedule_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Received History
  def send_received_history_csv(*args)
    data = received_history_data(*args)
    filename = "sss-received-history_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Repayment Detail
  def send_repayment_detail_csv(*args)
    data = repayment_detail_data(*args)
    filename = "sss-repayment_detail_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # Credit Information (History)のCSV
  def send_credit_information_history_csv(*args)
    csv = credit_limit_history(*args)
    filename = "sss-credit_information_history_#{filename_date}.csv"

    send_csv(csv, filename)
  end

  # Contractor User Detail
  def send_contractor_user_detail_csv(contractor_user)
    data = contractor_user_detail_data(contractor_user)
    filename = "contractor-user_detail_#{contractor_user.user_name}_#{filename_date}.csv"

    send_csv(data, filename)
  end

  # send_available_settings_detail_csv
  def send_available_settings_detail_csv(available_settings)
    data = available_settings_detail_data(available_settings)
    filename = "available_settings_detail_#{filename_date}.csv"

    send_csv(data, filename)
  end

  def send_calculate_payment_and_installment(payment = nil)
    data = calculate_payment_and_installment(payment)
    filename = "calculate_payment_and_installment_#{filename_date}.csv"

    send_csv(data, filename)
  end

  def calculate_payment_and_installment(payment = nil)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      attributes = CalculatePaymentAndInstallment.attribute_names
                    .reject { |el| ["created_at", "updated_at"].include?(el) }
      csv << attributes

      calculate_records = payment ? 
              CalculatePaymentAndInstallment.where(payment_id: payment.id) :
              CalculatePaymentAndInstallment.all

      calculate_records.each { |calculate_record| 
        csv << attributes.map{ |attr| 
          calculate_record.send(attr) 
        }
      }
    }
  end

  def available_settings_detail_data(available_settings)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'Dealer Type',
        'Available',
      ]

      available_settings[:cashback][:dealer_types].each { |dealer_type|
        csv << [
          dealer_type[:dealer_type_label][:label],
          !!dealer_type[:available] ? "Y" : "N",
        ]
      }
    }
  end

  def order_list_data(orders)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'Order No.',
        'Dealer',
        'Contractor TAX-ID',
        'Company Name(TH)',
        'Company Name(EN)',
        'Input Day',
        'Purchase Day',
        'Purchase Amount',
        'Installment',
        'Cancel Time',
        'Created Time',
        'Changed',
        'Product',
        'Site/Project Code',
        'Dealer Type',
        'Order Type',
        'Contractor Type',
        'Paid Up Day',
        'TOTAL AMOUNT',
        'Reschedule Order Number',
        'Reschedule Time',
        'Reschedule Order Type',
        'Region',
        'Bill Date',
        'BSCG',
        'BSCG AMT',
        'Non BSCG AMT',
        'Project',
      ]

      # ボディ行
      orders.eager_load(:product).each { |order|
        csv << [
          order.order_number,
          order.dealer&.dealer_name,
          order.contractor.tax_id,
          order.contractor.th_company_name,
          order.contractor.en_company_name,
          order.input_ymd || 'Not Yet',
          order.purchase_ymd,
          order.purchase_amount,
          order.installment_count,
          order.canceled_at&.strftime(date_fmt) || 'None',
          order.created_at.strftime(date_fmt),
          order_list_changed_fmt(order),
          order.product&.product_name || 'None',
          order.any_site&.site_code || 'None',
          order.dealer&.dealer_type_label&.fetch(:label),
          order.order_type.presence || 'None',
          order.contractor.contractor_type_label[:label],
          order.paid_up_ymd || 'None',
          order.amount_without_tax || '',
          order.rescheduled_new_order&.order_number || 'None',
          order.rescheduled_new_order&.rescheduled_at&.strftime(date_fmt) || 'None',
          order.rescheduled_new_order? ? order.order_number[0, 2] : 'None', # RS / RF / None
          order.region.presence || 'None',
          order.bill_date,
          order.second_dealer.present? ? 'Y' : 'N',
          order.second_dealer.present? ? order.second_dealer_amount : '',
          order.second_dealer.present? ? order.first_dealer_amount : '',
          order.belongs_to_project_finance?  ? 'Y' : 'N',
        ]
      }
    }
  end

  def due_basis_data
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'Contractor ID',
        'Due Date',
        'Paid up Date',
        'Total principal',
        'Total interest',
        'Total delay penalty',
        'Total amount',
        'Total balance',
        'TAXID',
        'Company Name (TH)',
        'Company Name (EN)'
      ]

      today_ymd = BusinessDay.today_ymd

      # ボディ行
      Payment.due_basis_data.each { |payment|
        csv << [
          payment.contractor.id,
          payment.due_ymd,
          payment.paid_up_ymd || 'None',
          payment.total_principal,
          payment.total_interest,
          payment.calc_total_late_charge(today_ymd),
          payment.calc_total_amount(today_ymd),
          payment.remaining_balance(today_ymd),
          payment.contractor.tax_id,
          payment.contractor.th_company_name,
          payment.contractor.en_company_name,
        ]
      }
    }
  end

  def order_basis_data
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'Order no.',
        'Contractor Type',
        'Company Name (TH)',
        'Company Name (EN)',
        'Dealer Type',
        'Dealer Name',
        'Input date',
        'Paid up Date',
        'Cancell date',
        'Rescheduled date',
        'Product name',
        'Due date',
        'Repayment date',
        'Payment times',
        'principal (billing)',
        'principal (payment)',
        'interest (billing)',
        'interest (payment)',
        'delay penalty (billing)',
        'delay penalty (payment)',
        'amount (billing)',
        'amount (payment)',
        'TAX ID',
        'Bill Date',
        'BSCG',
        'Site code',
        'project site code',
      ]

      today_ymd = BusinessDay.today_ymd

      Order.order_basis_data.each { |installment|
        csv << [
          installment.order.order_number, # 'Order no.'
          installment.order.contractor.contractor_type_label[:label], # Contractor Type
          installment.order.contractor.th_company_name, # 'Company Name (TH)'
          installment.order.contractor.en_company_name, # 'Company Name (EN)'
          installment.order.dealer&.dealer_type_label&.fetch(:label), # Dealer Type
          installment.order.dealer&.dealer_name, # 'Dealer Name'
          installment.order.input_ymd, # 'Input date'
          installment.order.paid_up_ymd, # 'Paid up Date'
          installment.order.canceled_at&.strftime(date_fmt), # 'Cancell date'
          installment.order.rescheduled_new_order&.rescheduled_at&.strftime(date_fmt), # Rescheduled date
          installment.order.product&.product_name, # 'Product name'
          installment.due_ymd, # 'Due date'
          installment.paid_up_ymd, # 'Repayment date'
          installment.installment_number, # 'Payment times'
          installment.principal, # 'principal (billing)'
          installment.paid_principal, # 'principal (payment)'
          installment.interest, # 'interest (billing)'
          installment.paid_interest, # 'interest (payment)'
          installment.calc_late_charge(today_ymd), # 'delay penalty (billing)'
          installment.paid_late_charge, # 'delay penalty (payment)'
          installment.calc_total_amount(today_ymd), # 'amount (billing)'
          installment.paid_total_amount, # 'amount (payment)'
          installment.order.contractor.tax_id, # TAX ID
          installment.order.bill_date, # Bill Date
          installment.order.second_dealer.present? ? 'Y' : 'N', # BSCG
          installment.order.site&.site_code, # Site code
          installment.order.project_phase_site&.site_code, # project site code
        ]
      }
    }
  end

  # Credit Information (History)のCSV
  def credit_limit_history(from_ymd, to_ymd)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'TAX ID',
        'Company Name (TH)',
        'Company Name (EN)',
        'Date',
        'Class',
        'Total Limit',
        'Dealer Type Limit',
        'Dealer Limit',
        'Comment',
        'Update By',
      ]

      Eligibility.credit_information_history_data(from_ymd, to_ymd).includes([:dealer_type_limits, :contractor, :create_user]).each do |eligibility|

        formatted_dealer_type_limits = []
        formatted_dealers = []

        eligibility.dealer_type_limits.each do |dealer_type_limit|
          formatted_dealer_type_limits.push(
            [dealer_type_limit.dealer_type_label[:label], dealer_type_limit.limit_amount.to_f].join(':')
          )
        end

        eligibility.dealer_limits.includes(:dealer).order('dealers.dealer_type').each do |dealer_limit|
          formatted_dealers.push(
            [dealer_limit.dealer.dealer_name, dealer_limit.limit_amount.to_f].join(':')
          )
        end

        csv << [
          eligibility.contractor.tax_id, # 'TAX-ID',
          eligibility.contractor.th_company_name, # 'Company Name (TH)'
          eligibility.contractor.en_company_name, # 'Company Name (EN)'
          eligibility.created_at.strftime(date_fmt), # 'Date'
          eligibility.class_type_label[:label], # 'Class'
          eligibility.limit_amount.to_f, # 'Total Limit'
          formatted_dealer_type_limits.join(';'), # 'Dealer Type Limit'
          formatted_dealers.join(';'), # 'Dealer Limit'
          eligibility.comment, # 'Comment'
          eligibility.create_user&.full_name, # 'Update By'
        ]
      end
    }
  end

  def bom
    %w[EF BB BF].map { |e| e.hex.chr }.join.force_encoding('UTF-8')
  end

  private

  def daily_received_amount_history_data(histories)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'TAX ID',
        'Company Name(TH)',
        'Company Name(EN)',
        'Date',
        'Amount',
        'Comment',
        'Operated At',
        'Operated By'
      ]

      # ボディ行
      histories.each { |history|
        csv << [
          history.contractor.tax_id,
          history.contractor.th_company_name,
          history.contractor.en_company_name,
          history.receive_ymd,
          history.receive_amount,
          history.comment,
          history.created_at.strftime(date_fmt),
          history.create_user&.full_name,
        ]
      }
    }
  end

  def site_list_data
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'ID',
        'Project',
        'Code',
        'Name',
        'TAX ID',
        'Company Name(TH)',
        'Company Name(EN)',
        'Dealer Code',
        'Dealer Name',
        'Limit',
        'Used',
        'Remaining',
        'Registered At',
        'Updated At',
      ]

      # ボディ行
      Site.not_close.includes([:contractor, :dealer]).each { |site|
        csv << [
          site.id, # 'ID'
          site.is_project ? 'Y' : 'N', # 'Project'
          site.site_code, # 'Code'
          site.site_name, # 'Name'
          site.contractor.tax_id, # 'TAX ID'
          site.contractor.th_company_name, # 'Company Name (TH)'
          site.contractor.en_company_name, # 'Company Name (EN)'
          site.dealer&.dealer_code, # 'Dealer Code'
          site.dealer&.dealer_name, # 'Dealer Name'
          site.site_credit_limit.to_f, # 'Limit'
          site.remaining_principal, # 'Used'
          site.available_balance, # 'Remaining'
          site.created_at.strftime(date_fmt), # 'Registered At'
          site.updated_at.strftime(date_fmt), # 'Updated At'
        ]
      }
    }
  end

  def reschedule_data(orders, exec_ymd, new_order_installments, fee_order_installments, total_installments)
    CSV.generate(csv_params) { |csv|
      # Before
      csv << ['Before']

      # ヘッダ行
      csv << [
        'Order Number', 'Principal', 'Interest', 'Delay Penalty', 'Total',
      ]

      # ボディ行
      orders.each do |order|
        csv << [
          order.order_number,
          order.remaining_principal,
          order.remaining_interest,
          order.calc_remaining_late_charge(exec_ymd),
          order.calc_remaining_balance(exec_ymd),
        ]
      end

      # Total
      csv << [
        'Total',
        orders.remaining_principal,
        orders.remaining_interest,
        orders.calc_remaining_late_charge(exec_ymd),
        orders.calc_remaining_balance(exec_ymd),
      ]

      # 空行
      csv << []

      # After
      csv << ['After']

      # ヘッダ行
      csv << [
        'Due Date', 'Principal', 'Interest', 'Reschedule Order Total', 'Fee Amount', 'Total',
      ]

      total_installments[:schedule].each.with_index do |schedule, i|
        csv << [
          schedule[:due_ymd],
          new_order_installments[:schedule][i]&.fetch(:principal, nil) || '-',
          new_order_installments[:schedule][i]&.fetch(:interest, nil) || '-',
          new_order_installments[:schedule][i]&.fetch(:amount, nil) || '-',
          fee_order_installments[:schedule][i]&.fetch(:amount, nil) || '-',
          schedule[:amount],
        ]
      end

      # Total
      csv << [
        'Total',
        new_order_installments[:total_principal],
        new_order_installments[:total_interest],
        new_order_installments[:total_amount],
        fee_order_installments[:total_amount],
        total_installments[:total_amount],
      ]
    }
  end

  def received_history_data(from_ymd, to_ymd)
    # 検索条件
    # 開始日
    from_date = from_ymd.present? ? Date.parse(from_ymd) : Time.at(0)
    # 終了日
    to_date = to_ymd.present? ? Date.parse(to_ymd).end_of_day : Time.zone.now.end_of_day

    receive_amount_histories =
      ReceiveAmountHistory.eager_load(:contractor)
        .where(created_at: from_date..to_date).order(created_at: :desc)

    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'ID',
        'Log Date',
        'TAX ID',
        'Company Name(TH)',
        'Company Name(EN)',
        'Repayment Amount',
        'Repayment Date',
        'Receive Comment',
      ]

      # ボディ行
      receive_amount_histories.each do |receive_amount_history|
        contractor = receive_amount_history.contractor

        csv << [
          receive_amount_history.id,
          receive_amount_history.created_at.strftime(date_fmt),
          contractor.tax_id,
          contractor.th_company_name,
          contractor.en_company_name,
          receive_amount_history.receive_amount.to_f,
          receive_amount_history.receive_ymd,
          receive_amount_history.comment
        ]
      end
    }
  end

  def repayment_detail_data(from_ymd, to_ymd)
    from_ymd = '00000000' if from_ymd.blank?
    to_ymd   = '99999999' if to_ymd.blank?

    # 検索条件
    receive_amount_details =
      ReceiveAmountDetail.where(repayment_ymd: from_ymd..to_ymd, deleted: false).order(id: :desc)

    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'Order no.',
        'Dealer Name',
        'Dealer Type',
        'TAX ID',
        'Company Name (TH)',
        'Company Name (EN)',
        'Bill Date',
        'Site Code',
        'Site Name',
        'Product Name',
        'Installment No.',
        'Due Date',
        'Input Date',
        'Switch Date',
        'Reschedule Date',
        'Receive amount id',
        'Repayment Date',
        'Principal',
        'Interest',
        'Delay penalty',
        'Principal (paid)',
        'Interest (paid)',
        'Delay penalty (paid)',
        'Principal (total)',
        'Interest (total)',
        'Delay penalty (total)',
        'Exceeded occurred',
        'Exceeded occur date',
        'Exceeded paid',
        'Cash back paid',
        'Cash back occurred',
        'Waive delay penalty',
      ]

      # ボディ行
      receive_amount_details.each do |row|
        csv << [
          row.order_number,
          row.dealer_name,
          row.dealer_type_label[:label],
          row.tax_id,
          row.th_company_name,
          row.en_company_name,
          row.bill_date,
          row.site_code,
          row.site_name,
          row.product_name,
          row.installment_number,
          row.due_ymd,
          row.input_ymd,
          row.switched_date&.strftime(ymd_fmt),
          row.rescheduled_date&.strftime(ymd_fmt),
          row.receive_amount_history_id,
          row.repayment_ymd,
          row.principal,
          row.interest,
          row.late_charge,
          row.paid_principal,
          row.paid_interest,
          row.paid_late_charge,
          row.total_principal,
          row.total_interest,
          row.total_late_charge,
          row.exceeded_occurred_amount,
          row.exceeded_occurred_ymd,
          row.exceeded_paid_amount,
          row.cashback_paid_amount,
          row.cashback_occurred_amount,
          row.waive_late_charge,
        ]
      end
    }
  end

  def contractor_user_detail_data(contractor_user)
    CSV.generate(csv_params) { |csv|
      # ヘッダ行
      csv << [
        'TAX-ID',
        'Contractor Name(EN)',
        'Contractor Name(TH)',
        'USERNAME(National ID)',
        'NAME',
        'User Type',
        'Title/Division',
        'Mobile Number',
        'E-mail',
        'LINE ID',
        'PDPA(latest) Agreed at'
      ]

      # ボディ行
      contractor = contractor_user.contractor

      csv << [
        contractor.tax_id,
        contractor.en_company_name,
        contractor.th_company_name,
        contractor_user.user_name,
        contractor_user.full_name,
        contractor_user.user_type,
        contractor_user.title_division,
        contractor_user.mobile_number,
        contractor_user.email,
        contractor_user.line_id,
        contractor_user.agreed_contractor_user_pdpa_versions.latest_agreed_at&.strftime(date_fmt)
      ]
    }
  end

  def send_csv(csv, file_name)
    send_data(bom + csv, type: 'text/csv', filename: file_name)
  end

  def csv_params
    {
      quote_char: '"',
      force_quotes: true,
      row_sep: "\r\n"
    }
  end

  def filename_date
    Time.zone.now.strftime('%Y%m%d-%H%M')
  end

  def date_fmt
    '%Y-%m-%d %H:%M:%S'
  end

  def ymd_fmt
    '%Y%m%d'
  end

  def order_list_changed_fmt(order)
    if order.approval? || order.registered?
      order.product_changed_at.strftime(date_fmt)
    elsif order.rejected?
      'Reject'
    else
      'None'
    end
  end
end
