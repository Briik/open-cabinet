include_recipe 'sandbox::secrets'
include_recipe 'sandbox::data_migrations'
include_recipe 'sandbox::prepare_app_directory'

execute 'unholy hack to allow passenger access to gems - part 1' do
  command "find /var/lib/gems -type d -exec chmod og+rx '{}' \\;"
  user 'root'
end

execute 'unholy hack to allow passenger access to gems - part 2' do
  command "find /var/lib/gems -type f -exec chmod og+r '{}' \\;"
  user 'root'
end

service 'nginx' do
  action :restart
end
