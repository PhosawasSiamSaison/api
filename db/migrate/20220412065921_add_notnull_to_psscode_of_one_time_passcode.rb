class AddNotnullToPsscodeOfOneTimePasscode < ActiveRecord::Migration[5.2]
  def change
    change_column_null :one_time_passcodes, :passcode, false
  end
end
