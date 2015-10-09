template "#{node[:myuscis][:app][:location]}/config/secrets.yml" do
  source 'secrets.yml.erb'
  action :create
  variables ({
              un: node[:myuscis][:app][:un],
              pw: node[:myuscis][:app][:pw],
              secret_key_base: node[:myuscis][:app][:secret_key_base],
              db_host: node[:databases][:host],
              db_un: node[:myuscis][:app][:db_un],
              db_pw: node[:myuscis][:app][:db_pw],
              import_key: node[:myuscis][:app][:import_key]
            })
end
