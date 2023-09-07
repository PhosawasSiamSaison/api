require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development?

  scope :api do
    # 共通
    resources :common, only: [] do
      collection do
        get :business_ymd
        get :labels
        get :types

        # LINEから呼ばれるアカウント連携のテンプレートメッセージの画像
        get :account_link_image

        # 開発用
        get :proc_business_day if Rails.env.development?
      end
    end

    namespace :online_apply do
      get  'check_tax_id',          to: 'index#check_tax_id'
      get  'check_national_id',     to: 'index#check_national_id'
      post 'send_validation_email', to: 'index#send_validation_email'
      post 'send_validation_sms',   to: 'index#send_validation_sms'
      post 'validate_passcode',     to: 'index#validate_passcode'
      post 'create_contractor',     to: 'index#create_contractor'
      post 'upload_selfie_image',   to: 'index#upload_selfie_image'
      post 'upload_card_image',     to: 'index#upload_card_image'
    end

    namespace :line_bot do
      post 'webhook', to: 'webhook#call'
    end

    namespace :jv do
      resources :common, only: [] do
        collection do
          get :header_info
          get :dealers
          get :areas
          get :products
          get :item_list
          get :detail_list
          get :rescheduled_order_list

          # Order Detail Dialog API
          get   :change_product_schedule
          patch :register_change_product

          # Credit Limit
          get :credit_limit_information
          post :update_credit_limit
          get :credit_limit_history

          # 汎用テスト用リクエスト
          get :test if Rails.env.development?
        end
      end

      resources :login, only: [] do
        collection do
          post :login
        end
      end

      resources :order_list, only: [] do
        collection do
          get :search
          get :order_detail
          get :download_csv
          patch :cancel_order
        end
      end

      resources :reschedule, only: [] do
        collection do
          get :contractor
          get :reschedule_total_amount
          get :order_list
          get :order_detail
          get :confirmation
          post :register
          get :download_csv
        end
      end

      resources :daily_received_amount_history, only: [] do
        collection do
          get :search
          get :download_csv
        end
      end

      resources :repayment_list, only: [] do
        collection do
          get :search
          get :status_list
        end
      end

      resources :repayment_history, only: [] do
        collection do
          get :search
          get :order_detail
        end
      end

      resources :change_product_apply_list, only: [] do
        collection do
          get :search
          get :detail
          patch :approve
        end
      end

      resources :change_password, only: [] do
        collection do
          patch :update_password
        end
      end

      resources :contractor_registration, only: [] do
        collection do
          get :available_settings
          post :register
        end
      end

      resources :contractor_update, only: [] do
        collection do
          get :contractor
          patch :update_contractor
        end
      end

      resources :available_settings_update, only: [] do
        collection do
          get :contractor
          patch :update_available_settings
        end
      end

      resources :scoring, only: [] do
        collection do
          # Actual Score
          get  :current_eligibility

          # Scoring
          get :execute_scoring
          get :scoring_result

          # Comment
          get  :comments
          post :create_comment
        end
      end

      resources :payment_for_dealer_list, only: [] do
        collection do
          get :search
          get :download_excel
        end
      end

      resources :dealer_list, only: [] do
        collection do
          get :search
        end
      end

      resources :dealer_detail, only: [] do
        collection do
          get    :dealer
          get    :dealer_user
          get    :dealer_users
          post   :create_dealer_user
          patch  :update_dealer_user
          delete :delete_dealer_user
        end
      end

      resources :dealer_registration, only: [] do
        collection do
          get :new_dealer
          post :create_dealer
        end
      end

      resources :dealer_update, only: [] do
        collection do
          patch :update_dealer
        end
      end

      resources :processing_list, only: [] do
        collection do
          get :search
        end
      end

      resources :processing_detail, only: [] do
        collection do
          get :notes
          get :basic_information
          get :available_settings
          get :more_information
          get :credit_status
          get :current_eligibility
          get :contractor_users
          patch :update_notes
          patch :approve_contractor
          patch :reject_contractor
        end
      end

      resources :contractor_list, only: [] do
        collection do
          get :search
        end
      end

      resources :contractor_detail, only: [] do
        collection do
          get :notes
          get :basic_information
          get :available_settings
          get :credit_status
          get :current_eligibility
          patch :update_notes
          get :more_information
          get :eligibility_histories
          post :create_eligibility
          get :qr_code
          post :upload_qr_code_image
          get :site_list
          patch :site_reopen
          post :create_gain_cashback
          post :create_use_cashback
          get :cashback_info
          get :delay_penalty_rate
          patch :update_delay_penalty_rate
        end
      end

      resources :contractor_user_list, only: [] do
        collection do
          get :search
        end
      end

      resources :contractor_user_detail, only: [] do
        collection do
          get :download_csv
        end
      end

      resources :contractor_user_registration, only: [] do
        collection do
          post :create_contractor_user
        end
      end

      resources :contractor_user_update, only: [] do
        collection do
          get    :contractor_user
          patch  :update_contractor_user
          delete :delete_contractor_user
        end
      end

      resources :user_list, only: [] do
        collection do
          get :search
        end
      end

      resources :user_registration, only: [] do
        collection do
          post :create_user
        end
      end

      resources :user_update, only: [] do
        collection do
          get    :jv_user
          patch  :update_user
          delete :delete_user
        end
      end

      resources :payment_from_contractor, only: [] do
        collection do
          get :payment_list
          get :evidence_list
          get :get_evidence
          get :contractor_status
          get :order_detail
          get :receive_amount_history
          patch :update_history_comment
          post :receive_payment
          patch :update_evidence_check
          patch :cancel_order
          patch :register_adjust_repayment
        end
      end

      resources :payment_from_contractor_list, only: [] do
        collection do
          get :search
          get :repayment_status_list
          get :switch_sub_dealer_information
          patch :switch_sub_dealer
        end
      end

      resources :billing_list, only: [] do
        collection do
          get :search
          get :daily_zip_list
          get :download_pdf
          get :download_zip
        end
      end

      resources :sms_spool_list, only: [] do
        collection do
          get :search
        end
      end

      resources :line_spool_list, only: [] do
        collection do
          get :search
        end
      end

      resources :email_history, only: [] do
        collection do
          get :search
        end
      end

      resources :reporting, only: [] do
        collection do
          get :check_can_download
          get :download_due_basis_csv
          get :download_order_basis_csv
          get :download_site_list_csv
          get :download_received_history_csv
          get :download_repayment_detail_csv
          get :download_credit_information_history_csv
        end
      end

      resources :product_list, only: [] do
        collection do
          get :search
        end
      end

      resources :global_available_product_setting, only: [] do
        collection do
          get :global_available_product_setting
          patch :update_setting
        end
      end

      resources :system_settings, only: [] do
        collection do
          get :settings
          patch :update_settings
        end
      end

      resources :project_registration, only: [] do
        collection do
          post :create_project
        end
      end

      resources :project_update, only: [] do
        collection do
          get :project
          patch :update_project
          delete :delete_project
        end
      end

      resources :project_list, only: [] do
        collection do
          get :search
          get :project_managers
        end
      end

      resources :project_detail, only: [] do
        collection do
          get :project
          get :search_photos
          get :project_info_phases
          get :project_info_contractors
          get :project_phase_list
          get :project_documents
          get :project_document
          patch :update_project_photo_comment
          post :create_project_phase
          post :upload_project_document
          patch :update_project_document
          delete :delete_project_document
        end
      end

      resources :project_phase_detail, only: [] do
        collection do
          get :project_phase
          get :project_basic_information
          get :evidence_list
          get :evidence
          get :payment_detail
          get :project_phase_site_list
          get :project_phase_site
          patch :update_project_phase
          delete :delete_project_phase
          patch :update_evidence_check
          post :create_project_phase_site
          patch :update_project_phase_site
          delete :delete_project_phase_site
          post :receive_payment
          get :receive_amount_history
          patch :update_history_comment
        end
      end
    end

    namespace :dealer do
      resources :common, only: [] do
        collection do
          get :header_info
        end
      end

      resources :login, only: [] do
        collection do
          post :login
        end
      end

      resources :change_password, only: [] do
        collection do
          patch :update_password
        end
      end

      resources :terms_of_service, only: [] do
        collection do
          post :agreed
        end
      end

      resources :home, only: [] do
        collection do
          get :graph1
          get :graph2
        end
      end

      resources :contractor_list, only: [] do
        collection do
          get :search
        end
      end

      resources :contractor_detail, only: [] do
        collection do
          get :basic_information
          get :contractor_users
          get :status
          get :current_eligibility
          get :more_information
        end
      end

      resources :user_list, only: [] do
        collection do
          get :user_list
        end
      end

      resources :user_registration, only: [] do
        collection do
          post :create_user
        end
      end

      resources :user_update, only: [] do
        collection do
          get    :dealer_user
          patch  :update_user
          delete :delete_user
        end
      end
    end

    namespace :contractor do
      resources :common, only: [] do
        collection do
          get :check_permission
        end
      end

      resources :personal_id_confirmation, only: [] do
        collection do
          post :auth_personal_id
        end
      end

      resources :login, only: [] do
        collection do
          post :login
          post :auth_line
        end
      end

      resources :pdpa_agreement, only: [] do
        collection do
          get :pdpa_agreement_status
          post :submit_pdpa_agreement
        end
      end

      resources :terms_of_service, only: [] do
        collection do
          get  :terms_of_service_versions
          get  :require_terms_of_service_versions
          post :agreed
        end
      end

      resources :change_temp_password, only: [] do
        collection do
          post :update_password
        end
      end

      resources :change_password, only: [] do
        collection do
          patch :update_password
        end
      end

      resources :top, only: [] do
        collection do
          get :credit_status
          get :payment
          get :qr_code
          get :projects
        end
      end

      resources :payment_status, only: [] do
        collection do
          get :payments
        end
      end

      resources :payment_detail, only: [] do
        collection do
          get :payment_detail
          get :change_product_schedule
          post :apply_change_product
        end
      end

      resources :order_detail, only: [] do
        collection do
          get :order_detail
        end
      end

      resources :rescheduled_old_orders, only: [] do
        collection do
          get :order_list
        end
      end

      resources :item_list, only: [] do
        collection do
          get :item_list
          get :detail_list # for CPAC Item List
        end
      end

      resources :reset_password, only: [] do
        collection do
          post :reset_password
          patch :update_password
        end
      end

      resources :evidence_of_payment, only: [] do
        collection do
          get  :evidence_list
          post :upload
        end
      end

      resources :cashbacks, only: [] do
        collection do
          get  :cashback_info
        end
      end

      resources :user_list, only: [] do
        collection do
          get :user_list
        end
      end

      resources :user_registration, only: [] do
        collection do
          post :create_user
        end
      end

      resources :user_update, only: [] do
        collection do
          get    :contractor_user
          patch  :update_user
          delete :delete_user
        end
      end

      resources :company, only: [] do
        collection do
          get :company_info
        end
      end

      resources :qr_code_for_payment, only: [] do
        collection do
          get :qr_code
        end
      end

      resources :credit_limit_detail, only: [] do
        collection do
          get :detail
        end
      end

      resources :line_setting, only: [] do
        collection do
          get :status
          patch :delink_account
        end
      end

      resources :user_verify_mode, only: [] do
        collection do
          get :verify_mode
          get :verify_mode_info
          get :send_otp_message
          patch :update_verify_mode
        end
      end

      resources :pdpa_list, only: [] do
        collection do
          get :pdpa_list
        end
      end

      resources :project_list do
        collection do
          get :search
        end
      end

      resources :project_detail do
        collection do
          get :project
          get :project_phase_list
        end
      end
    end

    namespace :project_manager do
      resources :common do
        collection do
          get :header_info
        end
      end

      resources :login do
        collection do
          post :login
        end
      end

      resources :change_password do
        collection do
          patch :update_password
        end
      end

      resources :user_registration do
        collection do
          post :create_user
        end
      end

      resources :user_update do
        collection do
          get :project_manager_user
          patch :update_user
          delete :delete_user
        end
      end

      resources :user_list do
        collection do
          get :search
        end
      end

      resources :project_list do
        collection do
          get :search
        end
      end

      resources :project_detail do
        collection do
          get :project
          get :search_photos
          get :project_info_phases
          get :project_info_contractors
          get :project_phase_list
          get :project_documents
        end
      end

      resources :project_phase_detail do
        collection do
          get :project_phase
          get :project_basic_information
          get :payment_detail
          get :evidence_list
          get :project_phase_site_list
          get :project_phase_site
          post :upload_evidence
        end
      end
    end

    namespace :rudy do
      get  'get_availability_status',    to: 'get_availability_status#call'
      get  'get_dealer_credit_status',   to: 'get_dealer_credit_status#call'
      get  'get_installment_info',       to: 'get_installment_info#call'
      post 'verify_account',             to: 'verify_account#call'
      post 'create_order',               to: 'create_order#call'
      post 'set_order_input_date',       to: 'set_order_input_date#call'
      post 'send_one_time_passcode_sms', to: 'send_one_time_passcode_sms#call'
      post 'auth_user_passcode',         to: 'login_from_rudy#call'
      post 'cancel_order',               to: 'cancel_order#call'
      post 'send_external_message',      to: 'send_external_message#call'
      post 'confirm_repayment',          to: 'confirm_repayment#call'
      # CPAC
      post 'send_new_site_information',    to: 'cpac/send_new_site_information#call'
      post 'create_site_information',      to: 'cpac/create_site_information#call'
      post 'send_update_site_information', to: 'cpac/send_update_site_information#call'
      post 'update_site_information',      to: 'cpac/update_site_information#call'
      post 'create_cpac_order',            to: 'cpac/create_cpac_order#call'
      post 'close_site_information',       to: 'cpac/close_site_information#call'
      get  'get_site_information',         to: 'cpac/get_site_information#call'
      # Project
      post 'send_new_project_information',    to: 'project/send_new_project_information#call'
      post 'create_project_information',      to: 'project/create_project_information#call'
      post 'send_update_project_information', to: 'project/send_update_project_information#call'
      post 'update_project_information',      to: 'project/update_project_information#call'
      post 'create_project_order',            to: 'project/create_project_order#call'
      post 'close_project_information',       to: 'project/close_project_information#call'
      get  'get_project_information',         to: 'project/get_project_information#call'
      # PF
      post 'create_project_finance_order',         to: 'project_finance/create_pf_order#call'
      post 'set_project_finance_site_limit',       to: 'project_finance/set_pf_site_limit#call'
      post 'approve_project_finance_site',         to: 'project_finance/approve_pf_site_limit#call'
      get  'get_project_finance_site_information', to: 'project_finance/get_site_information#call'
    end

    # URLをssaにしてrudyのcontrollerにつなげる
    scope :ssa do
      scope module: :rudy do
        post 'send_external_message', to: 'send_external_message#call'
      end
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
