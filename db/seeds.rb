# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# 初期管理者の作成
JvUser.create!(
  user_type: "md",
  user_name: "admin",
  full_name: "Admin",
  mobile_number: "00000000000",
  password: "saison2019",
  system_admin: true,
)

# システム日付の作成
BusinessDay.create!(id: 1, business_ymd: Date.today.strftime('%Y%m%d'))

# プロダクト
# 30日1回払い
Product.create!(
  id: 1,
  product_key: 1,
  product_name: "Product 1",
  number_of_installments: 1,
  sort_number: 1,
  annual_interest_rate:  0.0,
  monthly_interest_rate:  0.0
)
# 3回払い
Product.create!(
  id: 2,
  product_key: 2,
  product_name: "Product 2",
  number_of_installments: 3,
  sort_number: 4,
  annual_interest_rate: 2.51,
  monthly_interest_rate: 0.83,
)
# 6回払い
Product.create!(
  id: 3,
  product_key: 3,
  product_name: "Product 3",
  number_of_installments: 6,
  sort_number: 5,
  annual_interest_rate: 4.42,
  monthly_interest_rate: 0.73,
)
# 60日1回払い
# マイグレーションの中で作成(Product.insert_product4_record)
Product.create!(
  id: 4,
  product_key: 4,
  product_name: "Product 4",
  number_of_installments: 1,
  sort_number: 2,
  annual_interest_rate: 2.46,
  monthly_interest_rate: 1.23,
)
# 60日1回払い(無利子)
Product.create!(
  id: 5,
  product_key: 5,
  product_name: "Product 5",
  number_of_installments: 1,
  sort_number: 3,
  annual_interest_rate: 0.0,
  monthly_interest_rate:  0.0,
)
Product.create!(
  id: 6,
  product_key: 6,
  product_name: "Product 6",
  number_of_installments: 1,
  sort_number: 6,
  annual_interest_rate: 1.5,
  monthly_interest_rate: 0.75
)
Product.create!(
  id: 7,
  product_key: 7,
  product_name: "Product 7",
  number_of_installments: 1,
  sort_number: 7,
  annual_interest_rate: 2.5,
  monthly_interest_rate: 0.83
)

Product.create!(
  id: 8,
  product_key: 8,
  product_name: "Product 8",
  number_of_installments: 1,
  sort_number: 8,
  annual_interest_rate: 0.00,
  monthly_interest_rate: 0.00,
)

Product.create!(
  id: 9,
  product_key: 9,
  product_name: "Product 9",
  number_of_installments: 1,
  sort_number: 10,
  annual_interest_rate: 1.64,
  monthly_interest_rate: 0.82,
)

Product.create!(
  id: 10,
  product_key: 10,
  product_name: "Product 10",
  number_of_installments: 1,
  sort_number: 11,
  annual_interest_rate: 2.46,
  monthly_interest_rate: 0.82,
)

Product.create!(
  id: 11,
  product_key: 11,
  product_name: "Product 11",
  number_of_installments: 1,
  sort_number: 9,
  annual_interest_rate: 1.23,
  monthly_interest_rate: 1.23,
)

Product.create!(
  id: 12,
  product_key: 12,
  product_name: "Product 12",
  number_of_installments: 1,
  sort_number: 12,
  annual_interest_rate: 3.69,
  monthly_interest_rate: 1.23,
)

Product.create!(
  id: 13,
  product_key: 13,
  product_name: "Product 13",
  switch_sms_product_name: "Product 13",
  number_of_installments: 1,
  sort_number: 13,
  annual_interest_rate: 0,
  monthly_interest_rate: 0,
)

# システム設定
SystemSetting.create!(
  id: 1,
  credit_limit_additional_rate: 1.05,
  cbm_terms_of_service_version: 1,
  cpac_terms_of_service_version: 1,
  front_jv_version: "front_jv_version_1",
  front_c_version: "front_c_version_1",
  front_d_version: "front_d_version_1",
  front_pm_version: "front_pm_version_1"
)

# RUDY-API設定
RudyApiSetting.create!(
  id: 1,
  user_name: '',
  password: '',
  response_header_text: 'กรุณาติดต่อ SAISON',
  response_text: 'ในกรณีที่คุณลืมรหัสผ่านกรุณาติดต่อ SAISON เพื่อขอรหัสผ่านใหม่ในการเข้าระบบ\nโทร: 099-4444 4455 (** ติดต่อได้ตลอดชั่วโมง **)',
)

# Areaの作成
Area.create!(id: 1, area_name: "ภาคนครหลวง ( Metro )")
Area.create!(id: 2, area_name: "ภาคตะวันตก ( Western )")
Area.create!(id: 3, area_name: "ภาคตะวันออก ( Eastern )")
Area.create!(id: 4, area_name: "ภาคเหนือ ( Northern )")
Area.create!(id: 5, area_name: "ภาคตะวันออกเฉียงเหนือ ( North-Eastern )")
Area.create!(id: 6, area_name: "ภาคใต้ ( Southern )")

# DealerTypeSetting
DealerTypeSetting.create!(
  id: 1,
  dealer_type: :cbm,
  dealer_type_code: "cbm",
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "02-586-3021 หรือ ทางไลน์ Official @Siamsaison",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 2,
  dealer_type: :cpac,
  dealer_type_code: "cpac",
  group_type: :cpac_group,
  switch_auto_approval: true,
  sms_line_account: "@cpacsmilecredit",
  sms_contact_info: "LINE Official @CPACSmileCredit หรือกด https://line.me/R/ti/p/%40cpacsmilecredit หรือ โทร. 02-568-3021",
  sms_servcie_name: "CPAC Smile Credit by SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 3,
  dealer_type: :global_house,
  dealer_type_code: "global_house",
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "02-586-3021 หรือ ทางไลน์ Official @Siamsaison",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 4,
  dealer_type: :q_mix,
  dealer_type_code: "q_mix",
  group_type: :cpac_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "โทร. 02-568-3021 หรือทาง LINE Official @Qmixsaison หรือกด https://line.me/R/ti/p/%40qmixsaison",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 5,
  dealer_type: :transformer,
  dealer_type_code: "transformer",
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "02-586-3021 หรือ ทางไลน์ Official @Siamsaison",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 6,
  dealer_type: :solution,
  dealer_type_code: "cpac_sol",
  group_type: :project_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "โทร. 02-568-3021 หรือทาง LINE Official @Siamsaison หรือกด https://line.me/R/ti/p/%40siamsaison",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 7,
  dealer_type: :b2b,
  dealer_type_code: "b2b",
  group_type: :project_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "B2B Information",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 8,
  dealer_type: :nam,
  dealer_type_code: "nam",
  group_type: :cpac_group,
  switch_auto_approval: true,
  sms_line_account: "@Siamsaison",
  sms_contact_info: "NAM Information",
  sms_servcie_name: "SAISON CREDIT",
)
DealerTypeSetting.create!(
  id: 9,
  dealer_type: :bigth,
  dealer_type_code: 'bigth',
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)
DealerTypeSetting.create!(
  id: 10,
  dealer_type: :permsin,
  dealer_type_code: 'permsin',
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)
DealerTypeSetting.create!(
  id: 11,
  dealer_type: :scgp,
  dealer_type_code: 'scgp',
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)
DealerTypeSetting.create!(
  id: 12,
  dealer_type: :rakmao,
  dealer_type_code: 'rakmao',
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)
DealerTypeSetting.create!(
  id: 13,
  dealer_type: :cotto,
  dealer_type_code: 'cotto',
  group_type: :cbm_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)
DealerTypeSetting.create!(
  id: 14,
  dealer_type: :d_gov,
  dealer_type_code: 'd_gov',
  group_type: :project_group,
  switch_auto_approval: true,
  sms_line_account: '@siamsaison',
  sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
  sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
)

# GlobalAvailableSettingのデータを作成
global_available_setting_data = %w(normal sub_dealer individual government).map{|contractor_type|
  category_data = %w(purchase switch cashback).map{|category|
    dealer_type_data = ApplicationRecord.dealer_types.keys.map{|dealer_type|
      # Cashback以外
      if category != "cashback"
        product_data = Product.all.pluck(:product_key).map{|product_key|
          [product_key, true]
        }.to_h

        [dealer_type.to_sym, product_data]

      # Cashback
      else
        [dealer_type.to_sym, true]
      end
    }.to_h

    [category.to_sym, dealer_type_data]
  }.to_h

  [contractor_type.to_sym, category_data]
}.to_h

GlobalAvailableSetting.insert_category_data(global_available_setting_data)

pm1 = ProjectManager.create!(
  tax_id: "9999999999000",
  shop_id: "202",
  project_manager_name: "CPAC Solutions",
  dealer_type: 6
)

pm2 = ProjectManager.create!(
  tax_id: "8888888888000",
  shop_id: "223",
  project_manager_name: "B2B",
  dealer_type: 7
)

pm3 = ProjectManager.create!(
  tax_id: "1111111111000",
  shop_id: "308",
  project_manager_name: "Government",
  dealer_type: 14
)

ProjectManagerUser.create!(
  project_manager_id: pm2.id,
  user_type: 1,
  user_name: "B2B",
  full_name: "B2B",
  mobile_number: "0805752869",
  email: "b2badmin@gmail.com",
  create_user_id: 1,
  update_user_id: 1,
  password: "saison2019"
)

ProjectManagerUser.create!(
  project_manager_id: pm1.id,
  user_type: 1,
  user_name: "CPSL",
  full_name: "CPSL",
  mobile_number: "0805752869",
  email: "cpsadmin@gmail.com",
  create_user_id: 1,
  update_user_id: 1,
  password: "saison2019"
)

ProjectManagerUser.create!(
  project_manager_id: pm3.id,
  user_type: 1,
  user_name: "GOV",
  full_name: "GOV",
  mobile_number: "0805752869",
  email: "govadmin@gmail.com",
  create_user_id: 1,
  update_user_id: 1,
  password: "saison2019"
)
