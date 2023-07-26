# frozen_string_literal: true
# == Schema Information
#
# Table name: cashback_histories
#
#  id                        :bigint(8)        not null, primary key
#  contractor_id             :integer          not null
#  point_type                :integer          not null
#  cashback_amount           :decimal(10, 2)   not null
#  latest                    :boolean          not null
#  total                     :decimal(10, 2)   not null
#  exec_ymd                  :string(8)        not null
#  notes                     :string(100)
#  order_id                  :integer
#  receive_amount_history_id :bigint(8)
#  deleted                   :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  operation_updated_at      :datetime
#  lock_version              :integer          default(0)
#

class CashbackHistory < ApplicationRecord
  default_scope { where(deleted: 0) }

  scope :ordered, -> { order('created_at DESC') }

  belongs_to :contractor
  belongs_to :order, optional: true

  enum point_type: { gain: 1, use: 2 }

  class << self
    def latest
      find_by(latest: true)
    end

    def gain_latest
      gain.order(:created_at).last
    end

    def gain_total
      gain.sum(:cashback_amount).to_f
    end
  end

  def point_type_label
    enum_to_label('point_type')
  end

  def payment
    order.installments.first.payment
  end
end
