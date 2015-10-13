template "#{node[:myuscis][:app][:location]}/config/secrets.yml" do
  source 'secrets.yml.erb'
  action :create
  variables ({
              un: node[:myuscis][:app][:basic_auth_username],
              pw: node[:myuscis][:app][:basic_auth_password],
              secret_key_base: node[:myuscis][:app][:secret_key_base],
              db_host: node[:myuscis][:app][:database_host],
              db_un: node[:myuscis][:app][:database_username],
              db_pw: node[:myuscis][:app][:database_password],
              import_key: node[:myuscis][:app][:import_key]
            })
end
