require 'serverspec'
require 'net/ssh'

set :backend, :ssh

host = ENV['TARGET_HOST']

options = Net::SSH::Config.for(host)

options[:user] = 'ubuntu'
options[:keys] = ENV['TARGET_HOST_SSH_KEY_PATH']
options[:paranoid] = false

set :host,        options[:host_name] || host
set :ssh_options, options
set :disable_sudo, true
