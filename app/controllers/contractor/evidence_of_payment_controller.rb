# frozen_string_literal: true

class Contractor::EvidenceOfPaymentController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def evidence_list
    contractor = login_user.contractor

    render json: { success:   true,
                   evidences: format_evidence_list(contractor)
    }
  end

  def upload
    contractor    = login_user.contractor
    payment_image = register_payment_image(contractor)

    unless payment_image
      return render json: { success: false, errors: ['invalid_payment_image'] }
    end

    ActiveRecord::Base.transaction do
      contractor.evidences.create!(format_upload_evidence(payment_image))

      contractor.update!(check_payment: true)
    end

    render json: { success: true }
  end

  private

  def format_evidence_list(contractor)
    contractor.evidences.sort_list.map do |evidence|
      {
        id:                evidence.id,
        evidence_number:   evidence.evidence_number,
        comment:           evidence.comment,
        checked_at:        evidence.checked_at,
        checked_user_id:   evidence.checked_user_id,
        create_user_id:    evidence.contractor_user_id,
        created_at:        evidence.created_at,
        updated_at:        evidence.updated_at,
        payment_image_url: evidence.payment_image.present? ? url_for(evidence.payment_image) : nil,
      }
    end
  end

  def format_upload_evidence(payment_image)
    {
      active_storage_blob_id: payment_image.id,
      contractor_user_id:     login_user.id,
      evidence_number:        (Evidence.maximum(:evidence_number).to_i + 1).to_s.rjust(10, '0'),
      comment:                params[:comment]
    }
  end

  def register_payment_image(contractor)
    if params[:payment_image].present?
      parsed_image = parse_base64(params[:payment_image])
      filename = "evidence_#{Time.zone.now.strftime('%Y%m%d-%H%M')}"

      contractor.payment_images.attach(io: parsed_image, filename: filename)

      payment_image = contractor.payment_images.last

      if payment_image.filename.base == filename
        payment_image
      else
        raise "取得ファイルの不一致"
      end
    end
  end
end
