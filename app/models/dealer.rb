# frozen_string_literal: true
# == Schema Information
#
# Table name: dealers
#
#  id                   :bigint(8)        not null, primary key
#  tax_id               :string(13)       not null
#  area_id              :integer          not null
#  dealer_type          :integer          not null
#  dealer_code          :string(20)       not null
#  for_normal_rate      :decimal(5, 2)    default(2.0), not null
#  for_government_rate  :decimal(5, 2)    default(1.75)
#  for_sub_dealer_rate  :decimal(5, 2)    default(1.5)
#  for_individual_rate  :decimal(5, 2)    default(1.5)
#  dealer_name          :string(50)
#  en_dealer_name       :string(50)
#  bank_account         :string(1000)
#  address              :string(1000)
#  interest_rate        :decimal(5, 2)
#  status               :integer          default("active"), not null
#  create_user_id       :integer
#  update_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Dealer < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :area
  has_many :orders
  has_many :as_second_dealer_orders, class_name: :Order, foreign_key: :second_dealer
  has_many :dealer_users
  belongs_to :create_user, class_name: :JvUser, unscoped: true, optional: true
  belongs_to :update_user, class_name: :JvUser, unscoped: true, optional: true
  has_many :dealer_purchase_of_months
  has_many :dealer_limits
  has_many :eligibilities, through: :dealer_limits
  has_many :sites

  scope :as_first_dealer_orders, -> { orders.where(second_dealer: nil) }

  enum status: { active: 1, inactive: 2 }

  validates :tax_id, uniqueness: { case_sensitive: false }, presence: true, length: { is: 13 }
  validates :dealer_code, uniqueness: { case_sensitive: false }
  validates :dealer_name, presence: true, length: { maximum: 50 }
  validates :dealer_type, presence: true
  validates :en_dealer_name, presence: true, length: { maximum: 50 }
  validates :bank_account, length: { maximum: 1000 }
  validates :address, length: { maximum: 1000 }

  validates :for_normal_rate,     presence: true
  validates :for_government_rate, presence: true
  validates :for_sub_dealer_rate, presence: true
  validates :for_individual_rate, presence: true

  validates :for_normal_rate,     numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validates :for_government_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validates :for_sub_dealer_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000}, allow_nil: true
  validates :for_individual_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true

  class << self
    def search(params)
      relation = all.eager_load(:area)

      # Area(area_name)
      if params.dig(:search, :area_name).present?
        area_name = params.dig(:search, :area_name)
        relation  = relation.where("areas.area_name LIKE ?", "%#{sanitize_sql_like(area_name)}%")
      end

      # Dealer Type(dealer_type)
      if params.dig(:search, :dealer_type).present?
        dealer_type = params.dig(:search, :dealer_type)
        relation    = relation.where(dealer_type: dealer_type)
      end

      # Dealer Code(dealer_code)
      if params.dig(:search, :dealer_code).present?
        dealer_code = params.dig(:search, :dealer_code)
        relation    = relation.where("dealers.dealer_code LIKE ?", "#{sanitize_sql_like(dealer_code)}%")
      end

      # Dealer Name(dealer_name, en_dealer_name)
      if params.dig(:search, :dealer_name).present?
        dealer_name = params.dig(:search, :dealer_name)
        relation    = relation.where(
          "CONCAT(dealers.dealer_name, IFNULL(dealers.en_dealer_name, '')) LIKE ?",
          "%#{sanitize_sql_like(dealer_name)}%"
        )
      end

      # Show the Inactive Dealer
      show_inactive = params.dig(:search, :show_inactive)
      unless ActiveRecord::Type::Boolean.new.cast(show_inactive)
        relation = relation.where(status: :active)
      end

      relation
    end

    def paging(params)
      relation = self.all # paginate用にActiveRecord::Relation形式にする
      total_count = relation.count

      if params[:page].present? && params[:per_page].present?
        relation = paginate(params[:page], relation, params[:per_page])
      end

      [relation, total_count]
    end
  end

  def contractors
    Contractor.where(id: eligibilities.where(latest: true).pluck(:contractor_id))
  end

  def status_label
    enum_to_label('status')
  end

  def dealer_type_label
    # application_record に定義した localeを使用する
    enum_to_label('dealer_type', class_name: 'application_record')
  end

  def credit_limit_amount
    dealer_limit_amount = contractors.active.qualified.sum do |contractor|
      contractor.dealer_limit_amount(self)
    end

    dealer_limit_amount.round(2)
  end

  def remaining_principal
    target_contractors = contractors.where(status: :active, approval_status: :qualified)

    target_contractors.sum do |contractor|
      contractor.dealer_remaining_principal(self)
    end.round(2).to_f
  end

  def available_balance
    amount = (credit_limit_amount - remaining_principal).round(2).to_f

    # マイナスは0にする
    [amount, 0].max
  end

  def in_use_count
    # 未払いの注文があるコントラクターを集計する
    contractors.active.qualified.joins(:orders).eager_load(:orders).where(orders: { paid_up_ymd: nil }).count
  end

  def save_purchase_data(date = BusinessDay.today)
    begin_ymd = date.beginning_of_month.strftime(ymd_format)
    end_ymd = date.end_of_month.strftime(ymd_format)

    target_orders = orders.exclude_canceled.where(purchase_ymd: begin_ymd..end_ymd)

    dealer_purchase_of_months.create!(
      month:           date.strftime('%Y%m'),
      purchase_amount: target_orders.sum(:purchase_amount),
      order_count:     target_orders.count,
    )
  end

    # ordersにis_second_dealerの判定を追加する
  def gen_payment_target_orders(input_ymd)
    # Dealerとして登録されたオーダー
    target_orders = orders.payment_target_orders(input_ymd)

    # Second Dealerとして登録されたオーダー
    second_dealer_orders = as_second_dealer_orders.payment_target_orders(input_ymd)

    target_orders.each do |order|
      order.is_second_dealer = order.second_dealer.present? ? false : nil
    end

    second_dealer_orders.each do |order|
      order.is_second_dealer = true
    end

    target_orders + second_dealer_orders
  end

  # Dealerへの支払額 対象Orderの購入額の合計からtotal_invoice_amountを差し引いた額
  # total_invoice_amountは対象Orderの手数料の合計から計算
  def dealer_payment_total_amount(target_orders)
    total_calc_purchase_amount = target_orders.sum(&:calc_purchase_amount).round(2)
    total_transaction_fee = target_orders.sum(&:transaction_fee).round(2)
    total_value_added_tax = (total_transaction_fee * 0.07).round(2)
    total_withholding_tax = (total_transaction_fee * 0.03).round(2)
    total_invoice_amount = (total_transaction_fee + total_value_added_tax - total_withholding_tax).round(2)
    (total_calc_purchase_amount - total_invoice_amount).round(2).to_f
  end
end
