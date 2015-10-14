template "#{node[:myuscis][:app][:location]}/config/secrets.yml" do
  source 'secrets.yml.erb'
  action :create
  variables ({
              basic_auth_username: node[:myuscis][:app][:basic_auth_username],
              basic_auth_password: node[:myuscis][:app][:basic_auth_password],
              secret_key_base: node[:myuscis][:app][:secret_key_base],
              database_host: node[:myuscis][:app][:database_host],
              database_username: node[:myuscis][:app][:database_username],
              database_password: node[:myuscis][:app][:database_password],
              import_key: node[:myuscis][:app][:import_key]
            })
end
