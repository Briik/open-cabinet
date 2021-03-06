#lay down template files to support application
template "#{node[:myuscis][:app][:location]}/config/database.yml" do
  source 'database.yml.erb'
  action :create
  variables ({
              database_host: node[:myuscis][:app][:database_host],
              database_username: node[:myuscis][:app][:database_username],
              database_password: node[:myuscis][:app][:database_password],
            })
end

migrate = 'RAILS_ENV=production bundle exec rake db:create db:migrate'

results = '/tmp/output.txt'
file results do
  action :delete
end

bash 'create and migrate DB' do
  code <<-EOH
#{migrate} &>> #{results}
  EOH

  cwd node[:myuscis][:app][:location]
  #user 'root'
end