# frozen_string_literal: true

class Jv::ContractorDetailController < ApplicationController
  include AvailableSettingsFormatterModule, FileHelperModule
  before_action :auth_user
  before_action :parse_search_params, only: [:site_list]

  # Basic Info
  def basic_information
    contractor = Contractor.find(params[:contractor_id])

    basic_information = {
      tax_id:                      contractor.tax_id,
      contractor_type:             contractor.contractor_type_label[:label],
      use_only_credit_limit:       contractor.use_only_credit_limit,
      stop_payment_sms:            contractor.stop_payment_sms,
      th_company_name:             contractor.th_company_name,
      en_company_name:             contractor.en_company_name,
      employee_count:              contractor.employee_count,
      status:                      contractor.status_label,
      capital_fund_mil:            contractor.capital_fund_mil,
      application_number:          contractor.application_number,
      updated_at:                  contractor.updated_at,
      application_type_label:      contractor.application_type_label,
      enable_rudy_confirm_payment: contractor.enable_rudy_confirm_payment,
    }

    render json: {
      success: true,
      basic_information: basic_information,
    }
  end

  def available_settings
    contractor = Contractor.find(params[:contractor_id])
    available_settings = format_available_settings(contractor, detail_view: true)

    render json: {
      success: true,
      available_settings: available_settings,
    }
  end

  def more_information
    contractor                = Contractor.find(params[:contractor_id])
    contractor_view_formatter = ViewFormatter::ContractorFormatter.new(contractor)

    fomatted_contractor = contractor_view_formatter.format_more_information_with_hash(
      {
        register_user_name: contractor.register_user&.full_name,
        create_user_name:   contractor.create_user&.full_name,
        update_user_name:   contractor.update_user&.full_name,
        approval_user_name: contractor.approval_user&.full_name,
        applied_dealers:    contractor.applied_dealers.map{|applied_dealer|
          {
            dealer_name: applied_dealer.dealer.dealer_name,
            dealer_type: applied_dealer.dealer.dealer_type_label,
          }
        },
        # 添付された申込書類のファイル名とURL
        attached_documents: {
          # Company情報
          company_certificate: file_link(contractor.doc_company_certificate),
          vat_certification:   file_link(contractor.doc_vat_certification),
          office_store_map:    file_link(contractor.doc_office_store_map),
          financial_statement: file_link(contractor.doc_financial_statement),
          application_form:    file_link(contractor.doc_application_form),

          # Owner情報
          selfie_image:        file_link(contractor.selfie_image),
          card_image:          file_link(contractor.national_card_image),
          copy_of_national_id: file_link(contractor.doc_copy_of_national_id),
        }
      }
    )

    render json: {
      success: true,
      contractor: fomatted_contractor,
    }
  end


  # Credit Status
  def credit_status
    contractor = Contractor.find(params[:contractor_id])

    formatted_dealers = contractor.latest_dealer_limits.map {|dealer_limit|
      dealer = dealer_limit.dealer

      {
        dealer_type: dealer.dealer_type_label,
        dealer_name: dealer.dealer_name,
        available_balance: contractor.dealer_available_balance(dealer),
      }
    }

    status = {
      cashback:          contractor.cashback_amount,
      exceeded:          contractor.exceeded_amount,
      dealers:           formatted_dealers,
      available_balance: contractor.available_balance,
      used_amount:       contractor.remaining_principal
    }

    render json: {
      success: true,
      status: status,
    }
  end

  # Create Gain Cashback
  def create_gain_cashback
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    contractor = Contractor.find(params[:contractor_id])
    amount = params[:amount].to_f
    notes = params[:notes]
    order_id = nil

    contractor.create_gain_cashback_history(amount, BusinessDay.today_ymd, order_id, notes: notes)

    render json: {
      success: true
    }
  end

  # Create Use Cashback
  def create_use_cashback
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    contractor = Contractor.find(params[:contractor_id])
    amount = params[:amount].to_f
    notes = params[:notes]

    if contractor.cashback_amount >= amount
      contractor.create_use_cashback_history(amount, BusinessDay.today_ymd, notes: notes)
      render json: { success: true }
    else
      render json: { success: false, errors: set_errors('error_message.exceeding_cashback_amount_error')  }
    end
  end

  def qr_code
    contractor = Contractor.find(params[:contractor_id])

    qr_code_updated_at = contractor.qr_code_updated_at
    qr_code_image_url = contractor.qr_code_image.attached? ? url_for(contractor.qr_code_image) : nil

    render json: {
      success: true,
      updated_at: qr_code_updated_at,
      qr_code_image_url: qr_code_image_url,
    }
  end

  def upload_qr_code_image
    contractor = Contractor.find(params[:contractor_id])

    if params[:qr_code_image].present?
      image = parse_base64(params[:qr_code_image])
      file_name = "qr_code_image_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}"

      contractor.qr_code_image.attach(io: image, filename: file_name)
      contractor.update!(qr_code_updated_at: Time.zone.now)
    else
      # リクエストにデータがなければ削除する
      contractor.qr_code_image.purge
    end

    render json: { success: true }
  end


  # Note
  def notes
    contractor = Contractor.find(params[:contractor_id])

    render json: { success: true, notes: format_notes(contractor) }
  end

  def update_notes
    contractor = Contractor.find(params[:contractor_id])

    contractor.notes_updated_at  = Time.zone.now
    contractor.notes_update_user = login_user

    if contractor.update(update_notes_params)
      render json: { success: true }
    else
      render json: { success: false, errors: contractor.error_messages }
    end
  end


  # Site List
  def site_list
    sites, total_count = Site.search(params)

    render json: {
      success: true,
      sites: sites.map {|site|
        {
          id:                site.id,
          site_code:         site.site_code,
          site_name:         site.site_name,
          dealer: site.dealer && {
            id:          site.dealer.id,
            dealer_code: site.dealer.dealer_code,
            dealer_name: site.dealer.dealer_name,
            dealer_type: site.dealer.dealer_type_label,
          },
          site_credit_limit: site.site_credit_limit.to_f,
          used_amount:       site.remaining_principal,
          available_balance: site.available_balance,
          closed:            site.closed,
          order_count:       site.orders.count,
          created_at:        site.created_at,
          updated_at:        site.updated_at,
          can_reopen:        can_site_reopen(login_user, site),
        }
      },
      total_count: total_count
    }
  end

  # Site Reopen
  def site_reopen
    # 管理者もしくはMDのみ許可
    unless login_user.system_admin || login_user.md?
      return render json: { success: false, errors: set_errors('error_message.permission_denied') }
    end

    site = Site.find_by!(id: params[:id], closed: true)

    site.update!(closed: false)
    
    render json: { success: true }
  end

  # Score
  def current_eligibility
    contractor = Contractor.find(params[:contractor_id])

    eligibility = {
      current_limit_amount: contractor.credit_limit_amount,
      current_class_type:   contractor.class_type_label,
    }

    render json: { success: true, eligibility: eligibility }
  end

  def cashback_info
    contractor = Contractor.find(params[:contractor_id])

    cashback_histories = contractor.cashback_histories.ordered
    paginated_cashback_histories, total_count = [
      cashback_histories.paginate(params[:page], cashback_histories, params[:per_page]), cashback_histories.count
    ]

    render json: {
      success: true,
      cashback_histories: paginated_cashback_histories.map {|cashback_history|
        {
          exec_ymd:        cashback_history.exec_ymd,
          notes:           cashback_history.notes,
          point_type:      cashback_history.point_type,
          cashback_amount: cashback_history.cashback_amount.to_f,
          order_number:    cashback_history.order&.order_number
        }
      },
      total_count: total_count,
    }
  end

  # Delay Penaty Rate
  def delay_penalty_rate
    contractor = Contractor.find(params[:contractor_id])

    render json: {
      success: true,
      delay_penalty_rate: contractor.delay_penalty_rate,
    }
  end

  def update_delay_penalty_rate
    contractor = Contractor.find(params[:contractor_id])
    delay_penalty_rate = params[:delay_penalty_rate]

    errors = contractor.update_delay_penalty_rate(delay_penalty_rate, login_user)

    if errors.blank?
      render json: {
        success: true,
      }
    else
      render json: {
        success: false,
        errors: errors,
      }
    end
  end

  private
  def can_site_reopen(login_user, site)
    return false if site.open?

    return login_user.system_admin || login_user.md?
  end

  def format_notes(contractor)
    return {
      notes: contractor.notes,
    }
  end

  def update_notes_params
    params.require(:notes).permit(:notes)
  end

  def create_eligibility_params
    params.require(:eligibility).permit(:class_type, :comment, :limit_amount)
  end
end
