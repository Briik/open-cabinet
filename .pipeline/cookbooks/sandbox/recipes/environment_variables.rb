template "#{node[:myuscis][:app][:location]}/config/initializers/0_environment_variables.rb" do
  source '0_environment_variables.rb.erb'
  action :create
  variables ({
              disable_ga: node[:myuscis][:app][:disable_ga],
              disable_auth: node[:myuscis][:app][:disable_auth],
              disable_newrelic: node[:myuscis][:new_relic][:disable_newrelic]
              secret_key_base: node[:myuscis][:app][:secret_key]
            })
end
