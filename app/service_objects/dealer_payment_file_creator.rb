class DealerPaymentFileCreator
  attr_reader :filename_date, :split_zip_orders

  # Dealer Payment のファイルデータを作成する
  def call(dealer, input_ymd)
    # 対象オーダーの取得
    orders = dealer.gen_payment_target_orders(input_ymd)

    # オーダーが分割される場合
    if can_orders_split?(orders)
      # 複数エクセルファイルをzipにする
      file_data, zip_file_name = create_zip_data(dealer, input_ymd)

      return [file_data, mime_type(:zip), zip_file_name]
    else
      # オーダーが分割されない（エクセルファイルが１つの場合）
      file_data = create_excel_data(dealer, input_ymd, orders)

      return [file_data.stream, mime_type(:excel), excel_file_name()]
    end
  end

  private

  def create_excel_data(dealer, input_ymd, orders)
    DealerPaymentExcelCreator.new.call(dealer, input_ymd, orders)
  end

  def create_zip_data(dealer, input_ymd)
    splited_orders = split_zip_orders()

    rand_str = random_str(8)
    zip_dir_name       = "sss-dealer_payment_#{filename_date}"
    tmp_zip_path       = File.join('tmp', "#{rand_str}.zip")
    tmp_excel_dir_path = File.join('tmp', rand_str)

    # エクセルの一時ディレクトリを作成
    Dir.mkdir(tmp_excel_dir_path)

    Zip::OutputStream.open(tmp_zip_path) do |out|
      splited_orders.each do |order_type, orders|
        # エクセルファイル名を取得
        excel_file_name = excel_file_name(order_type)

        # エクセルファイルを作成
        file_data = create_excel_data(dealer, input_ymd, orders)

        # 一時的に保存するエクセルファイルのパス
        excel_path = File.join(tmp_excel_dir_path, excel_file_name)

        # エクセルファイルの保存
        file_data.write(excel_path)

        # 展開後のzipのディレクトリ名とPDFのファイル名
        out.put_next_entry(File.join(zip_dir_name, excel_file_name))

        buffer = File.read(excel_path)
        out.write(buffer)
      end
    end

    # 返却するファイルを取得する
    zip_data = File.read(tmp_zip_path)

    # 一時ディレクトリの削除
    File.delete(tmp_zip_path)

    # 一時保存したエクセルファイルとディレクトリの削除
    Dir.each_child(tmp_excel_dir_path){|f| File.delete(File.join(tmp_excel_dir_path, f))}
    Dir.delete(tmp_excel_dir_path)

    [zip_data, "#{zip_dir_name}.zip"]
  end

  # 処理が並列した場合にファイル名が重複しないようにランダムの文字列を生成する
  def random_str(length)
    (0...length).map{ ('A'..'Z').to_a[rand(26)] }.join
  end

  def excel_file_name(order_type = nil)
    type =
      case order_type
      when :normal_orders
        'normal_'
      when :sub_dealer_orders
        'sub_dealer_'
      when :individual_orders
        'individual_sub_dealer_'
      when :government_orders
        'government_project_'
      else # zipにならないエクセルの分岐
        ''
      end

    "sss-dealer_payment_#{type}#{filename_date}.xlsx"
  end

  # zipファイルにするエクセル用にオーダーを分ける
  def split_zip_orders(order_array = nil)
    return @split_zip_orders if @split_zip_orders

    # nilの場合はすでに取得済みの想定
    raise 'ロジックエラー' if order_array.nil?

    # 配列から変換する
    orders = Order.where(id: order_array.map(&:id)).eager_load(:contractor)

    normal_orders     = orders.where(contractor: Contractor.normal)
    sub_dealer_orders = orders.where(contractor: Contractor.sub_dealer)
    individual_orders = orders.where(contractor: Contractor.individual)
    government_orders = orders.where(contractor: Contractor.government)

    @split_zip_orders = {}

    # 存在するオーダーのみハッシュを追加する
    if normal_orders.present?
      merge_second_dealer_attr_to_orders(order_array, normal_orders)

      @split_zip_orders[:normal_orders] = normal_orders
    end

    if sub_dealer_orders.present?
      merge_second_dealer_attr_to_orders(order_array, sub_dealer_orders)

      @split_zip_orders[:sub_dealer_orders] = sub_dealer_orders
    end

    if individual_orders.present?
      merge_second_dealer_attr_to_orders(order_array, individual_orders)

      @split_zip_orders[:individual_orders] = individual_orders
    end

    if government_orders.present?
      merge_second_dealer_attr_to_orders(order_array, government_orders)

      @split_zip_orders[:government_orders] = government_orders
    end

    @split_zip_orders
  end

  # is_second_dealerの値を復元する
  def merge_second_dealer_attr_to_orders(order_array, orders)
    raise if order_array.class != Array

    orders.map do |order|
      order.is_second_dealer = order_array.find{|_order| _order.id == order.id}.is_second_dealer
    end
  end

  # エクセルファイルが複数になるかの判定
  def can_orders_split?(orders)
    split_zip_orders(orders).length > 1
  end

  def mime_type(type)
    raise if type.blank?

    {
      excel: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      zip:   'application/zip',
    }[type]
  end

  def filename_date
    # 同じ時刻を返す
    return @filename_date if @filename_date

    @filename_date = Time.zone.now.strftime('%Y%m%d-%H%M')
  end
end