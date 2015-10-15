config_dir = node[:myuscis][:https_ssl][:config_dir]
cert_password = node[:myuscis][:https_ssl][:certPass]

cert_object_name = node[:myuscis][:https_ssl][:cert_object_name]
key_object_name = node[:myuscis][:https_ssl][:key_object_name]

directory "/etc/httpd/ssl" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  recursive true
end

#Pull down the cert from S3 
amazon_s3_download "Download the cert" do
  path node[:myuscis][:https_ssl][:config_dir] + cert_object_name
  key cert_object_name
  bucket node[:myuscis][:https_ssl][:bucket_name]
  owner 'root'
  group 'root'
end

#Pull down the key from S3
amazon_s3_download "Download the key" do
  path node[:myuscis][:https_ssl][:config_dir] + key_object_name
  key key_object_name
  bucket node[:myuscis][:https_ssl][:bucket_name]
  owner 'root'
  group 'root'
end

#Decrypt the cert and specify location
bash "Decrypt ssl cert" do
  user "root"
  cwd config_dir
  code <<-EOH
  openssl enc -d -aes-256-cbc -k #{cert_password} -in #{cert_object_name} -out #{node[:myuscis][:https_ssl][:cert_filename]}
  EOH
end

#Decrypt the key and specify location
bash "Decrypt ssl key" do
  user "root"
  cwd config_dir
  code <<-EOH
  openssl enc -d -aes-256-cbc -k #{cert_password} -in #{key_object_name} -out #{node[:myuscis][:https_ssl][:key_filename]}
  EOH
end
