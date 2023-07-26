source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4', '< 0.6.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Http Client
gem 'faraday', '0.17.6'
gem 'httpclient'

# Pagination
gem 'kaminari'

# Aws Sdk
gem 'aws-sdk-rails', '~> 2'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-sns', '~> 1.1'

# Credentials
gem 'rails-env-credentials'

# Background Job
gem 'sidekiq'

# CLI支援ツール
gem 'highline'

# エクセル作成
gem 'rubyXL'

# PDF作成
gem 'prawn'
gem 'prawn-table'

# ZIPファイルの作成
gem 'rubyzip'

# LINE
gem 'line-bot-api'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails', '4.11.1'

  # カバレッジ
  gem "simplecov"

  # API Doc
  gem 'rswag'
end

group :test do
  # Testing
  gem 'rspec-rails'
  gem 'database_rewinder'
  gem 'timecop'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Insert DB Schema
  gem 'annotate'

  # Capistrano
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  # GitHook
  gem 'overcommit'

  gem 'rb-readline'
  gem 'dotenv-rails'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
