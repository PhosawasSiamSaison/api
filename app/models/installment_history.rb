# frozen_string_literal: true
# == Schema Information
#
# Table name: installment_histories
#
#  id                    :bigint(8)        not null, primary key
#  contractor_id         :bigint(8)
#  order_id              :bigint(8)
#  installment_id        :integer
#  payment_id            :bigint(8)
#  from_ymd              :string(255)
#  to_ymd                :string(255)      default("99991231")
#  paid_principal        :decimal(10, 2)   not null
#  paid_interest         :decimal(10, 2)   not null
#  paid_late_charge      :decimal(10, 2)   not null
#  late_charge_start_ymd :string(8)
#  deleted               :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operation_updated_at  :datetime
#  lock_version          :integer          default(0)
#

class InstallmentHistory < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor, optional: true
  belongs_to :order, optional: true
  belongs_to :installment
  belongs_to :payment, optional: true

  scope :except_first_record, -> { where.not(id: first_record.id) }

  class << self
    def by_target_ymd(target_ymd)
      # 指定日に該当するhistoryを取得
      where('from_ymd <= ? AND to_ymd >= ?', target_ymd, target_ymd).first
    end

    def first_record
      order(:from_ymd).first
    end
  end

  def set_installment_paid_amount
    # installmentの値をセットする
    self.paid_principal   = installment.paid_principal
    self.paid_interest    = installment.paid_interest
    self.paid_late_charge = installment.paid_late_charge
  end
end
