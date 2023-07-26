class SendReceivePaymentMessageAndEmail
  attr_reader :contractor, :payment_ymd, :payment_amount

  def initialize(contractor, payment_ymd, payment_amount)
    @contractor = contractor
    @payment_ymd = payment_ymd
    @payment_amount = payment_amount
  end

  def call
    if payment_amount.to_f > 0
      # SMS and LINE
      SendMessage.receive_payment(contractor, payment_ymd, payment_amount)

      # Email
      SendMail.receive_payment(contractor, payment_ymd, payment_amount)
    end
  end
end
