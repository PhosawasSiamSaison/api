# frozen_string_literal: true

class Contractor::TermsOfServiceController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version

  # 最新バージョンチェック用
  def require_terms_of_service_versions
    render json: {
      success: true,
      require_terms_of_service_versions: format_require_agree_terms_of_service_types,
    }
  end

  def agreed
    params_type = params.fetch(:terms_of_service)[:type].to_sym
    params_version = params.fetch(:terms_of_service)[:version].to_i

    latest_terms_of_service_version = SystemSetting.get_terms_of_service_version(params_type)

    # バージョンが古い場合はエラー
    if params_version != latest_terms_of_service_version
      raise UnmatchTermsOfService
    end

    login_user.agree_terms_of_service(params_type, params_version)

    render json: {
      success: true,
      require_terms_of_service_versions: format_require_agree_terms_of_service_types,
      require_change_password: login_user.temp_password.present?,
    }
  end

  # 表示用
  def terms_of_service_versions
    render json: {
      success: true,
      terms_of_service_versions: format_terms_of_service_types,
    }
  end

  private
  def type_label(type)
    case type
    when TermsOfServiceVersion::SUB_DEALER
      'Sub Dealer'
    when TermsOfServiceVersion::INDIVIDUAL
      'Individual Sub Dealer'
    when TermsOfServiceVersion::INTEGRATED
      nil
    else
      ApplicationRecord.dealer_type_labels[type]
    end
  end

  def format_terms_of_service_types
    # 対象の規約のタイプを返す
    login_user.target_terms_of_service_types.map {|terms_of_service_type|
      {
        type: {
          code: terms_of_service_type,
          label: type_label(terms_of_service_type),
        },
      }
    }
  end

  def format_require_agree_terms_of_service_types
    # 同意が必要な残りのtypeのみを返す
    login_user.require_agree_terms_of_service_types.map {|terms_of_service_type|
      {
        type: {
          code: terms_of_service_type,
          label: type_label(terms_of_service_type),
        },
        version: SystemSetting.get_terms_of_service_version(terms_of_service_type)
      }
    }
  end
end
