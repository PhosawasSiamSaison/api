require "rails_helper"
require 'simplecov'
require_relative './support/global_available_settings_data'

SimpleCov.start 'rails'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # DB settings
  config.use_transactional_examples = false

  # Rspec起動時に１度だけ実行
  config.before(:suite) do
    DatabaseRewinder.clean_all

    FactoryBot.create(:area, id: 1)

    # Dealer Type Settingsを作成
    ApplicationRecord.dealer_types.keys.each {|dealer_type|
      FactoryBot.create(:dealer_type_setting, dealer_type.to_sym)
    }

    FactoryBot.create(:product1, id: 1)
    FactoryBot.create(:product2, id: 2)
    FactoryBot.create(:product3, id: 3)
    FactoryBot.create(:product4, id: 4)
    FactoryBot.create(:product5, id: 5)
    FactoryBot.create(:product8, id: 8)

    # Global Available Settingsを作成
    GlobalAvailableSetting.insert_category_data(global_available_settings_test_data)
  end

  # 各specのあとに実行
  config.after(:each) do
    #DatabaseRewinder.clean
    DatabaseRewinder.clean_with(
      :_,
      except: [
        "global_available_settings",
        "dealer_type_settings",
        "products",
        "areas"
      ]
    )
  end
end
