class AddBinaryAttribute < ActiveRecord::Migration[5.2]
  def change
    begin
      ActiveRecord::Base.connection.execute("start transaction") 
      sss_users_sql =  "ALTER TABLE jv_users MODIFY user_name VARCHAR(20) BINARY;"
      ssd_users_sql =  "ALTER TABLE dealer_users MODIFY user_name VARCHAR(20) BINARY;"
      sspm_users_sql = "ALTER TABLE project_manager_users MODIFY user_name VARCHAR(20) BINARY;"
      ActiveRecord::Base.connection.execute(sss_users_sql)
      ActiveRecord::Base.connection.execute(ssd_users_sql)
      ActiveRecord::Base.connection.execute(sspm_users_sql)
      ActiveRecord::Base.connection.execute("commit")
    rescue
      ActiveRecord::Base.connection.execute("rollback")
      raise "エラーが発生したのでロールバックしました"
    end
  end
end