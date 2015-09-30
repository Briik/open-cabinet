template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  action :create
  variables (lazy {
                {:java_home => discover_java_location,
                 :app_location => node[:myuscis][:app][:location]}
              }
            )
end