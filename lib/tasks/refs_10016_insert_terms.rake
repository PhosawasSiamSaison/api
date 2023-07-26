desc '規約同意移行スクリプト'
task refs_10016_insert_terms: :environment do
  p '開始'
  count = 0

  ContractorUser.all.each do |contractor_user|
    # 除外するContractor User IDのチェック
    next if exclude_contractor_user_ids.include?(contractor_user.id)

    # 既にterms_of_serviceのレコードがあれば除外
    next if contractor_user.agreed_terms_of_services.present?

    dealer_type = contractor_user.contractor.main_dealer.dealer_type

    begin
      # main_dealerのdealer_typeで規約を同意
      contractor_user.agree_terms_of_service(dealer_type, dealer_type_version(dealer_type))
      count += 1

      # sub_dealerの規約の同意
      if contractor_user.contractor.sub_dealer
        contractor_user.agree_terms_of_service('sub_dealer', 1)
        count += 1
      end
    rescue Exception => e
      p "!!! エラー !!!"
      p "ContractorUserID: #{contractor_user.id}"
      p e
    end
  end

  p "完了。#{count}件挿入"
end

def exclude_contractor_user_ids
  [
    3,15,16,22,24,27,31,33,40,61,63,64,68,69,72,73,76,85,113,139,145,149,154,156,173,178,186,195,
    198,226,228,234,237,247,248,249,251,258,263,273,286,287,288,289,291,295,301,305,308,309,314,
    315,320,330,334,338,345,346,352,354,355,358,366,371,377,385,386,392,400,404,405,406,408,417,
    419,422,427,431,432,436,440,449,452,455,457,465,470,477,487,492,495,497,499,503,506,517,518,
    525,528,532,534,541,544,545,546,549,551,556,563,564,567,570,571,578,582,587,591,594,596,598,
    604,606,607,608,615,616,617,629,630,631,633,635,638,641,643,645,646,649,651,652,655,659,662,
    665,667,670,672
  ]
end

def dealer_type_version(dealer_type)
  (dealer_type == 'cbm' || dealer_type == 'cpac') ? 2 : 1
end

def error_msg
  p "!!! エラー !!!"
end