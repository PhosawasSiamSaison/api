# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::UpdateTransactionFeeHistoryStatus do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190215')
  end

  describe 'UpdateTransactionFeeHistoryStatus' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }

    before do
      FactoryBot.create(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190216",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2
      )
      old_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190215",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "active"
      )

      old_transaction.save(validate: false)

      delete_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190201",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "deleted",
        deleted: 1
      )

      delete_transaction.save(validate: false)
      # order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
      #   product: product1, installment_count: product1.number_of_installments,
      #   purchase_ymd: '20190101', input_ymd: '20190110', input_ymd_updated_at: '2019-01-10 10:00:00',
      #   purchase_amount: 1000.01, order_user: contractor_user)

      # payment = Payment.create!(contractor: contractor, due_ymd: '20190215',
      #   total_amount: 1000.01, status: 'next_due')

      # FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
      #   due_ymd: '20190215', principal: 900.01, interest: 100)
    end

    it 'should change status of Transaction Fee History correctly' do
      BusinessDay.update_ymd!("20190216")
      old_transaction = dealer.transaction_fee_histories.find_by(apply_ymd: "20190215", status: "active")
      expect(old_transaction).to be_present

      delete_transaction = dealer.transaction_fee_histories.unscope(where: :deleted).find_by(apply_ymd: "20190201", status: "deleted", deleted: 1)
      expect(delete_transaction).to be_present

      transaction_fee_history = dealer.transaction_fee_histories.find_by(apply_ymd: "20190216", status: "scheduled")

      Batch::UpdateTransactionFeeHistoryStatus.exec

      transaction_fee_history.reload
      old_transaction.reload
      delete_transaction.reload
      expect(delete_transaction.status).to eq("deleted")
      expect(transaction_fee_history.status).to eq("active")
      expect(old_transaction.status).to eq("retired")

      BusinessDay.update_ymd!("20190217")
      Batch::UpdateTransactionFeeHistoryStatus.exec
      transaction_fee_history.reload
      expect(transaction_fee_history.status).to eq("active")
    end

    # it 'statusがover_dueになること' do
    #   payment = Payment.find_by(due_ymd: '20190215')

    #   expect(payment.status).to eq 'next_due'

    #   Batch::UpdateOverDueStatus.exec

    #   expect(payment.reload.status).to eq 'over_due'
    # end
  end
end
