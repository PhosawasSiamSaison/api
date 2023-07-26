class Task10250 < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :switch_sms_product_name, :string, null: true, after: :product_name
    add_column :dealer_type_settings, :sms_line_account, :string, null: false, after: :dealer_type_code

    Product.reset_column_information
    DealerTypeSetting.reset_column_information

    # 既存の商品に switch_sms_product_name を追加する
    Product.all.each do |product|
      product.update!(switch_sms_product_name: switch_sms_product_names_data[product.product_key])
    end

    DealerTypeSetting.all.each do |dealer_type_setting|
      dealer_type_setting.update!(sms_line_account: sms_line_account(dealer_type_setting.dealer_type))
    end
  end

  # 既存のProductに追加するデータ
  def switch_sms_product_names_data
    {
      2 => 'ผ่อนชำระ 3 เดือน ดอกเบี้ย 0.83%/เดือน',
      3 => 'ผ่อนชำระ 6 เดือน ดอกเบี้ย 0.73%/เดือน',
      4 => 'ชำระเต็มจำนวน 60 วัน ดอกเบี้ย 1.23%/เดือน',
      5 => 'ชำระเต็มจำนวน 60 วัน ดอกเบี้ย 0%',
      6 => 'ชำระเต็มจำนวน 60 วัน ดอกเบี้ย 1.5%',
      7 => 'ชำระเต็มจำนวน 90 วัน ดอกเบี้ย 2.5%',
    }
  end

  # 既存のDealerTypeSettingに追加するデータ
  def sms_line_account(dealer_type)
    case dealer_type
    when 'cpac'
      '@cpacsmilecredit'
    when 'q_mix'
      '@qmixsaison'
    else
      '@siamsaison'
    end
  end
end
