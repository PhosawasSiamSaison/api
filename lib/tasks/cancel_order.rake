desc 'オーダーのキャンセル(運用)'
task :cancel_order, ['order_id'] => :environment do |task, args|
  order_id = args[:order_id]

  order = Order.find_by(id: order_id)

  if order.blank?
    error_msg
    p "order.id: #{order_id} は見つかりませんでした"
    next
  end

  if order.canceled?
    error_msg
    p "order.id: #{order_id} はすでにキャンセル済です"
    next
  end

  if order.paid_total_amount > 0
    error_msg
    p "order.id: #{order_id} はすでに #{order.paid_total_amount} が支払い済みです"
    next
  end

  CancelOrder.new(order.id, nil, do_check_error: false).call

  p "キャンセルが完了しました。"
end

def error_msg
  p "!!! エラー !!!"
end