desc 'Siteに対して、最新のOrderのDealerを設定(運用)'
task update_site_dealer: :environment do
  sites = Site.all

  sites.each do |site|
    order = site.orders.order(created_at: :desc).first

    if order.blank?
      p "tax_id: #{site.contractor.tax_id} のContractorのsite内にOrderは存在しません( site_id: #{site.id}, site_code: #{site.site_code} )"
      next
    end

    begin
      site.update!(dealer_id: order.dealer_id)
    rescue Exception => e
      error_msg
      p e
      next
    end
  end

  p '完了'
end

def error_msg
  p "!!! エラー !!!"
end