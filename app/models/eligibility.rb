# frozen_string_literal: true
# == Schema Information
#
# Table name: eligibilities
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :integer          not null
#  limit_amount         :decimal(13, 2)   not null
#  class_type           :integer          not null
#  latest               :boolean          default(TRUE), not null
#  comment              :string(100)      not null
#  create_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Eligibility < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :create_user, class_name: :JvUser, unscoped: true, optional: true
  has_many :dealer_type_limits
  has_many :dealer_limits

  validates :comment, length: { maximum: 100} , presence: true
  validates :class_type, presence: true
  validates :limit_amount, presence: true
  validates :limit_amount, numericality: { less_than: 100_000_000_000 }, allow_blank: true

  class << self
    def latest
      find_by(latest: true)
    end

    def ordered
      order('created_at DESC')
    end

    def credit_information_history_data(from_ymd, to_ymd)
      # 値がなければ全期間を指定
      from_date = from_ymd.present? ? Date.parse(from_ymd) : Time.new(2000, 01, 01)
      to_date   = to_ymd.present?   ? Date.parse(to_ymd).end_of_day : Time.new(9999, 12, 31)

      where(created_at: from_date..to_date).order(contractor_id: :asc, created_at: :desc)
    end
  end

  def class_type_label
    enum_to_label('class_type', class_name: 'application_record')
  end
end
