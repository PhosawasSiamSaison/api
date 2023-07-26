class AddScoringClassSetting < ActiveRecord::Migration[5.2]
  def change
    ScoringClassSetting.create!(
      class_a_min: 29,
      class_b_min: 19,
      class_c_min: 12,
      class_a_limit_amount: 100_000,
      class_b_limit_amount: 50_000,
      class_c_limit_amount: 50_000,
      latest: true
    )
  end
end
