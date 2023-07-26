begin
  # CSVダウンロード時にサーバーダウンした場合に起動時にフラグを戻す
  ActiveRecord::Base.connection.execute('UPDATE `system_settings` SET `system_settings`.`is_downloading_csv` = FALSE')
rescue
  # エラーは無視する
end
