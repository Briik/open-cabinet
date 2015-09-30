raise 'The [:new_relic][:app_name] must be set as an override' unless node[:myuscis][:new_relic][:app_name]

template "#{node[:myuscis][:app][:location]}/config/newrelic.yml" do
  source 'newrelic.yml.erb'
  action :create
  variables ({
              monitorMode: (not node[:myuscis][:new_relic][:disable_newrelic])
            })
end