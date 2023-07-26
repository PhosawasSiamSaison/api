set :application, "jv-api"
set :rails_env,'production'

set :repo_url, 'ssh://git@gitlab2.jbc-s.net:29294/jbcdev/jv/api.git'
set :branch, ENV['B'] || "main"

set :deploy_to, "/usr/local/src/#{fetch(:application)}"

set :format, :pretty
set :log_level, :debug
set :pty, false

set :linked_files, %w{}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

set :keep_releases, 5

set :bundle_binstubs, nil

namespace :deploy do
    task :restart_services do
      on roles(:app) do
          execute "sudo systemctl stop jv-puma"
          execute "sudo systemctl start jv-puma"
          execute "sudo systemctl stop jv-sidekiq"
          execute "sudo systemctl start jv-sidekiq"
      end
    end
    after :finishing, 'deploy:restart_services'
    after :finishing, 'deploy:cleanup'
end