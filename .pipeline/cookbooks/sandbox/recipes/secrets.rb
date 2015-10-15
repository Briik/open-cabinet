template "#{node[:myuscis][:app][:location]}/config/secrets.yml" do
  source 'secrets.yml.erb'
  action :create
  variables ({
              basic_auth_username: node[:myuscis][:app][:un],
              basic_auth_password: node[:myuscis][:app][:pw],
              secret_key_base: node[:myuscis][:app][:secret_key_base],
              database_host: node[:myuscis][:app][:db_host],
              database_username: node[:myuscis][:app][:db_un],
              database_password: node[:myuscis][:app][:db_pwd],
              import_key: node[:myuscis][:app][:import_key]
            })
end
