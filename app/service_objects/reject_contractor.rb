# frozen_string_literal: true
#
class RejectContractor
  attr_reader :contractor
  attr_reader :reject_user

  def initialize(contractor, reject_user)
    @contractor  = contractor
    @reject_user = reject_user
  end

  def call
    contractor.reject_user = reject_user
    contractor.rejected_at = Time.zone.now
    contractor.approval_status = :rejected

    contractor.save!
  end
end
