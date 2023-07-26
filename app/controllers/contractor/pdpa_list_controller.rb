# frozen_string_literal: true

class Contractor::PdpaListController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def pdpa_list
    contractor_user = login_user

    # 同意したpdpa_versionsのレコード
    agreed_contractor_user_pdpa_versions = contractor_user.agreed_contractor_user_pdpa_versions

    render json: {
      success: true,
      pdpa_list: agreed_contractor_user_pdpa_versions.order(created_at: :DESC).map{|record|
        {
          id: record.id,
          file_url: record.pdpa_version.file_url,
          version: record.pdpa_version.version,
          agreed_at: record.created_at,
        }
      }
    }
  end
end
