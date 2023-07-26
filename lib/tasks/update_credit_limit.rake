desc 'Credit Limitの更新(運用)'
task :update_credit_limit, ['tax_id','limit_amount','comment'] => :environment do |task, args|
  tax_id       = args[:tax_id]
  limit_amount = args[:limit_amount].to_f
  comment      = args[:comment]

  contractor = Contractor.qualified.find_by(tax_id: tax_id)

  if contractor.blank?
    error_msg
    p "tax_id: #{tax_id} のContractorは見つかりませんでした"
    next
  end

  if limit_amount < 0
    error_msg
    p "tax_id: #{tax_id} のlimit_amountが不正です"
    next
  end

  if comment.blank?
    error_msg
    p "tax_id: #{tax_id} のcommentが不正です"
    next
  end

  eligibilities = contractor.eligibilities
  if eligibilities.latest.blank?
    error_msg
    p "tax_id: #{tax_id} のlatestが存在しません"
    next
  end
  class_type = eligibilities.latest.class_type
  old_limit_amount = contractor.credit_limit_amount

  begin
  errors = contractor.create_eligibility(limit_amount, class_type, comment, nil)
  if errors.present?
    raise Exception.new(errors)
  end
  rescue Exception => e
    error_msg
    p e
    next
  end

  p "完了　credit_limit:#{old_limit_amount}　=>  #{limit_amount}"
end

def error_msg
  p "!!! エラー !!!"
end