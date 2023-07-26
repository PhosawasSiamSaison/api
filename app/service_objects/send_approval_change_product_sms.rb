class SendApprovalChangeProductSms
  def initialize(change_product_apply)
    @change_product_apply = change_product_apply
  end

  def call
    change_product_apply = @change_product_apply
    contractor           = change_product_apply.contractor
    contractor_users     = contractor.contractor_users

    # 請求系のSMSの送信を止める判定
    return nil if contractor.stop_payment_sms

    contractor_users.sms_targets.each do |contractor_user|
      SendMessage.send_approval_change_product(contractor_user)
    end
  end
end
