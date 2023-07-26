# frozen_string_literal: true

class ApprovalContractor
  attr_reader :contractor
  attr_reader :approval_user

  def initialize(contractor, approval_user)
    @contractor = contractor
    @approval_user = approval_user
  end

  def call
    contractor.approval_status = "qualified"
    contractor.approval_user   = approval_user
    contractor.approved_at     = Time.zone.now

    # ContractorUser登録時エラーのユーザ名を保持する
    error_user_name = ''
    begin
      contractor_users = []

      Contractor.transaction do
        contractor.save!

        # 必ずユーザーを作成する
        # 作成するユーザーを取得
        contractor_users = BuildContractorUsers.new(contractor, approval_user).call

        contractor_users.each { |contractor_user|
          # エラーが発生するユーザーを特定する
          error_user_name = contractor_user.user_name if contractor_user.invalid?

          contractor_user.save!
        }

        # オンライン申し込みの場合はオーナーのPDPA同意レコードを作成する
        if contractor.applied_online?
          owner_user = contractor_users.first
          owner_user.create_latest_pdpa_agreement!
        end
      end

      # SMSを送信
      contractor_users.each { |contractor_user|
        SendMessage.send_register_user_on_approval(contractor_user)
      }

      nil
    rescue ActiveRecord::RecordInvalid => e
      e.record.error_messages.map{|msg| "#{error_user_name}: #{msg}"}
    end
  end
end
