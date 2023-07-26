# frozen_string_literal: true

class Jv::ProjectDetailController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search_photos]

  def project
    project = Project.find(params[:project_id])

    render json: {
      success: true,
      project: {
        id: project.id,
        project_code: project.project_code,
        project_type: project.project_type_label,
        project_name: project.project_name,
        project_manager: {
          id: project.project_manager.id,
          project_manager_name: project.project_manager.project_manager_name,
        },
        project_limit: project.project_limit.to_f,
        project_value: project.project_value.to_f,
        start_ymd: project.start_ymd,
        finish_ymd: project.finish_ymd,
        contract_registered_ymd: project.contract_registered_ymd,
        address: project.address,
        progress: project.progress,
        project_owner: project.project_owner,
        delay_penalty_rate: project.delay_penalty_rate.to_f,
        status: project.status_label,
        purchase_amount: project.total_purchase_amount,
        paid_repayment_amount: project.paid_total_amount_with_refund,
        repayment_amount: project.project_value.to_f,
      }
    }
  end

  def search_photos
    sites = ProjectPhaseSite.search(params)

    site_codes = sites.map(&:site_code)

    site_infos = RudyReportSaison.new(site_codes).exec

    photos = []

    sites.each do |site|
      site_info = site_infos[site.site_code]
      next unless site_info

      # 複数のurlのカンマ区切りの文字列
      project_images = site_info['project_images']
      next unless project_images.present?

      photo_image_urls = project_images.split(',')

      photo_image_urls.each do |photo_image_url|
        photos <<  {
          file_name: photo_image_url.split('/').last,
          phase_number: site.project_phase.phase_number,
          photo_image_url: photo_image_url,
          contractor: {
            id: site.contractor.id,
            tax_id: site.contractor.tax_id,
            en_company_name: site.contractor.en_company_name,
            th_company_name: site.contractor.th_company_name
          },
          site: {
            site_code: site.site_code,
            site_name: site.site_name
          }
        }
      end
    end

    total_count = photos.count

    # paginate
    if params[:page].present? && params[:per_page].present?
      photos = photos.slice((params[:page].to_i - 1) * params[:per_page].to_i, params[:per_page].to_i)
    end

    # comment
    file_names = photos.map { |photo| photo[:file_name] }
    comments = ProjectPhotoComment.where(file_name: file_names).map { |item| [item.file_name, item.comment] }.to_h

    photos.each do |photo|
      photo[:comment] = comments[photo[:file_name]]
    end

    render json: {
      success: true,
      photos: photos,
      total_count: total_count
    }
  end

  def update_project_photo_comment
    project_photo_comment = ProjectPhotoComment.find_or_initialize_by(file_name: project_photo_comment_params[:file_name])

    comment = project_photo_comment_params[:comment]

    unless comment.present?
      project_photo_comment.delete if project_photo_comment.persisted?

      return render json: { success: true }
    end

    project_photo_comment.create_user = login_user unless project_photo_comment.persisted?
    project_photo_comment.update_user = login_user

    if project_photo_comment.update(project_photo_comment_params)
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: project_photo_comment.error_messages
      }
    end
  end

  # photo登録・更新・検索条件のPhase一覧
  def project_info_phases
    phases = Project.find(params[:project_id]).project_phases

    render json: {
      success: true,
      phases: phases.map do |phase|
        {
          id: phase.id,
          phase_number: phase.phase_number
        }
      end
    }
  end

  # photo登録・更新・検索条件のContractor一覧
  def project_info_contractors
    project = Project.find(params[:project_id])

    # Phaseに紐づくcontractor一覧（登録・更新用）
    if params[:project_phase_id].present?
      phase = project.project_phases.find(params[:project_phase_id])
      contractors = phase.contractors.distinct

    # Projectに紐づくcontractor一覧（検索条件用）
    else
      contractors = project.contractors.distinct
    end

    render json: {
      success: true,
      contractors: contractors.map do |contractor|
        {
          id: contractor.id,
          tax_id: contractor.tax_id,
          th_company_name: contractor.th_company_name,
          en_company_name: contractor.en_company_name,
        }
      end
    }
  end

  def create_project_phase
    project = Project.includes(:project_phases).find(params[:project_id])
    phase = project.project_phases.new(project_phase_params)

    # Projectに紐づくPhaseが削除済みも含めて一件もない場合
    unless project.project_phases.unscope(where: :deleted).exists?
      phase.attributes = { phase_number: 1 }
    else
      max_num = project.project_phases.unscope(where: :deleted).maximum(:phase_number) + 1

      phase.attributes = { phase_number: max_num }
    end

    if phase.save
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: phase.error_messages
      }
    end
  end

  def project_phase_list
    project = Project.find(params[:project_id])
    project_phases = project.project_phases

    progress_data = project.project_phase_sites.progress_data

    render json: {
      success: true,
      max_phase_number: project_phases.unscope(where: :deleted).maximum(:phase_number) || 0,
      phases: project_phases.map do |phase|
        {
          id: phase.id,
          phase_number: phase.phase_number,
          phase_name: phase.phase_name,
          phase_value: phase.phase_value.to_f,
          phase_limit: phase.phase_limit.to_f,
          start_ymd: phase.start_ymd,
          finish_ymd: phase.finish_ymd,
          due_ymd: phase.due_ymd,
          status: phase.status_label,
          sites: phase.project_phase_sites.map {|site|
            {
              id: site.id,
              site_code: site.site_code,
              site_name: site.site_name,
              phase_limit: site.phase_limit.to_f,
              site_limit: site.site_limit.to_f,
              progress: progress_data[site.site_code],
              status: site.status_label,
              contractor: {
                id: site.contractor.id,
                tax_id: site.contractor.tax_id,
                th_company_name: site.contractor.th_company_name,
                en_company_name: site.contractor.en_company_name,
              },
              paid_up_ymd: site.paid_up_ymd,
              used_amount: site.used_amount,
              available_balance: site.available_balance,
              refund: site.refund_amount,
            }
          },
          progress: phase.average_progress_from_data(progress_data),
          surcharge: phase.surcharge_amount,
          paid_repayment_amount: phase.paid_repayment_amount,
          repayment_amount: phase.repayment_amount,
        }
      end
    }
  end

  def upload_project_document
    project = Project.find(params[:project_id])

    document = project.project_documents.new(upload_document_params)
    document.create_user = login_user
    document.update_user = login_user

    if document.save
      file = parse_base64(params[:project_document][:file_data])
      document.file.attach(io: file, filename: document.file_name)

      render json: { success: true }
    else
      render json: {
        success: false,
        errors: document.error_messages
      }
    end
  end

  def update_project_document
    document = ProjectDocument.find(params[:project_document_id])
    document.update_user = login_user

    if document.update(upload_document_params)
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: document.error_messages
      }
    end
  end

  def delete_project_document
    document = ProjectDocument.find(params[:project_document_id])

    document.file.purge
    document.delete

    render json: { success: true }
  end

  def project_documents
    project = Project.find(params[:project_id])
    documents = project.project_documents

    render json: {
      success: true,
      documents: documents.map do |document|
        {
          id: document.id,
          file_name: document.file_name,
          file_type: document.file_type_label,
          ss_staff_only: document.ss_staff_only,
          comment: document.comment,
          created_at: document.created_at,
          create_user_name: document.create_user.full_name,
          file_url: url_for(document.file)
        }
      end
    }
  end

  def project_document
    document = ProjectDocument.find(params[:project_document_id])

    render json: {
      success: true,
      document: {
        id: document.id,
        file_name: document.file_name,
        file_type: document.file_type_label,
        ss_staff_only: document.ss_staff_only,
        comment: document.comment,
        created_at: document.created_at,
        create_user_name: document.create_user.full_name,
      }
    }
  end

  private

  def project_photo_comment_params
    params.require(:project_photo_comment).permit(:file_name, :comment)
  end

  def project_phase_params
    params.require(:phase)
      .permit(:phase_name, :phase_value, :phase_limit, :start_ymd, :finish_ymd, :due_ymd)
  end

  def upload_document_params
    params.require(:project_document).permit(:file_type, :file_name, :comment, :ss_staff_only)
  end
end
