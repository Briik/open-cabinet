default[:myuscis][:app][:name] = nil
default[:myuscis][:app][:location] = "/webapps/#{node[:myuscis][:app][:name]}"

default[:myuscis][:app][:service_user] = 'www-data'
default[:http_proxy][:proxy_host] = ''
default[:http_proxy][:proxy_port] = ''

