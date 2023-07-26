# frozen_string_literal: true

class Jv::ReportingController < ApplicationController
  include CsvModule

  before_action :auth_user
  before_action :check_permission

  before_action :start_download, except: [:check_can_download]
  after_action :finish_download, except: [:check_can_download]

  def check_can_download
    # 他でダウンロード中は抑制する(メモリ不足で落ちるのを防ぐ)
    if SystemSetting.is_downloading_csv
      return render json: { success: false, errors: set_errors('error_message.is_downloading_csv')}
    end

    render json: { success: true }
  end

  def download_due_basis_csv
    send_due_basis_csv

    exec_system_command(1)
  rescue => e
    finish_download
    raise e
  end

  def download_order_basis_csv
    send_order_basis_csv

    exec_system_command(2)
  rescue => e
    finish_download
    raise e
  end

  def download_site_list_csv
    send_site_list_csv

    exec_system_command(3)
  rescue => e
    finish_download
    raise e
  end

  def download_received_history_csv
    send_received_history_csv(params[:from_ymd], params[:to_ymd])

    exec_system_command(4)
  rescue => e
    finish_download
    raise e
  end

  def download_repayment_detail_csv
    send_repayment_detail_csv(params[:from_ymd], params[:to_ymd])

    exec_system_command(5)
  rescue => e
    finish_download
    raise e
  end

  def download_credit_information_history_csv
    send_credit_information_history_csv(params[:from_ymd], params[:to_ymd])

    exec_system_command(6)
  rescue => e
    finish_download
    raise e
  end

  private
  def check_permission
    errors = check_permission_errors(login_user.md? || login_user.system_admin)
    return render json: { success: false, errors:  errors } if errors.present?
  end

  def start_download
    SystemSetting.update!(is_downloading_csv: true)
  end

  def finish_download
    SystemSetting.update!(is_downloading_csv: false)
  end

  # CSV出力後にスクリプトを実行する（本番のみ、メモリの開放などの想定）
  def exec_system_command(report_number)
    path = JvService::Application.config.try(:after_reporting_script_path)

    # シェルスクリプトの実行（引数にレポートの識別子を渡す）
    system("sh #{path} #{report_number}") if path.present?
  end
end
