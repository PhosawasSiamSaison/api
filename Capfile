# Load DSL and Setup Up Stages
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/console'
require 'capistrano/rbenv'
set :rbenv_type, :system
set :rbenv_ruby, File.read(File.expand_path('../.ruby-version',__FILE__)).strip
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
