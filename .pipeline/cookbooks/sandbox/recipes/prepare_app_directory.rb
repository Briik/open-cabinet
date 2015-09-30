raise 'The [:myuscis][:app][:name] must be set as an override' unless node[:myuscis][:app][:name]

directory node[:myuscis][:app][:location] do
  owner node[:myuscis][:app][:service_user]
  group node[:myuscis][:app][:service_user]
  mode '0755'
  recursive true
  action :create
end

execute 'recursive chown' do
  command "chown -R #{node[:myuscis][:app][:service_user]}:#{node[:myuscis][:app][:service_user]} /webapps"
  user 'root'
end