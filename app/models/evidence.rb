# == Schema Information
#
# Table name: evidences
#
#  id                     :bigint(8)        not null, primary key
#  contractor_id          :bigint(8)        not null
#  contractor_user_id     :bigint(8)        not null
#  active_storage_blob_id :bigint(8)        not null
#  evidence_number        :string(255)      not null
#  comment                :text(65535)
#  checked_at             :datetime
#  checked_user_id        :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  operation_updated_at   :datetime
#

class Evidence < ApplicationRecord
  belongs_to :contractor
  belongs_to :contractor_user, unscoped: true
  belongs_to :checked_user, class_name: :JvUser, unscoped: true, optional: true
  belongs_to :blob, class_name: "ActiveStorage::Blob", optional: true

  scope :sort_list, -> { order(created_at: :desc, id: :desc) }

  class << self
    def get_prev_id(evidence)
      where('created_at >= ? and id > ?', evidence.created_at, evidence.id).reverse.first&.id
    end

    def get_next_id(evidence)
      where('created_at <= ? and id < ?', evidence.created_at, evidence.id).first&.id
    end
  end

  def payment_image
    contractor.payment_images.find(active_storage_blob_id)
  end
end
