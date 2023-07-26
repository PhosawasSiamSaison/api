class ReduceSiteLimit
  def call(installment, reduce_amount)
    raise '不正な金額' if reduce_amount <= 0

    ActiveRecord::Base.transaction do
      site = installment.order.site

      # 減らすsite_limitを算出する。少ない方を取得(SiteLimitを超えないようにする(拡張分))
      reduce_site_limit_amount = [site.site_credit_limit, reduce_amount].min

      # AdjustRepaymentの際に戻すSiteLimit分を保持する
      # (カラム追加前のデータは対象外なので、NULL以外を対象にする判定(対象外はNULLで更新済み))
      if installment.reduced_site_limit.present?
        # 減らす金額を保持する
        installment.reduced_site_limit += reduce_site_limit_amount
        installment.save!
      end

      # 減らす
      site.site_credit_limit -= reduce_site_limit_amount
      site.save!
    end
  end
end