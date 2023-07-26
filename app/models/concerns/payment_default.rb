# frozen_string_literal: true

# InputDateがあるInstallment(Order)が一つもないPaymentを除外したPayments
class PaymentDefault < Payment
  default_scope {
    exclude_not_input_ymd
  }
end
