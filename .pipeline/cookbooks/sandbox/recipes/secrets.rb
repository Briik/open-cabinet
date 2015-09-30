template "#{node[:myuscis][:app][:location]}/config/secrets.yml" do
  source 'secrets.yml.erb'
  action :create
  variables ({
              saml_endpoint_url: node[:myuscis][:app][:saml_endpoint_url],
              callback_url: node[:myuscis][:app][:callback_url],
              auth_user: node[:myuscis][:app][:basic_auth_username],
              auth_pass: node[:myuscis][:app][:basic_auth_password],
              usps_api_key: node[:myuscis][:app][:usps_api_key],
              secret_key_base: node[:myuscis][:app][:secret_key_base],
              pdf_service_rest_host: node[:myuscis][:app][:pdf_service_rest_host],
              elis_password: node[:myuscis][:app][:elis_password],
              portal_endpoint: node[:myuscis][:app][:portal_endpoint],
              sales_force_endpoint: node[:myuscis][:app][:sales_force_endpoint],
              sales_force_client_id: node[:myuscis][:app][:sales_force_client_id],
              sales_force_client_secret: node[:myuscis][:app][:sales_force_client_secret],
              sales_force_user_name: node[:myuscis][:app][:sales_force_user_name],
              sales_force_password: node[:myuscis][:app][:sales_force_password]
            })
end
