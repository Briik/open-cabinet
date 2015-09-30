require 'serverspec'

describe file('/webapps/myuscis-sandbox/config/secrets.yml') do
  it { should be_file }
  it { should contain 'secret_key_base: fakesecret_key_base'}
  it { should contain 'BASIC_AUTH_USERNAME: fakebasic_auth_username' }
  it { should contain 'BASIC_AUTH_PASSWORD: fakebasic_auth_password' }
  it { should contain 'USPS_USER: fakeusps_api_key' }
  it { should contain 'pdf_service_rest_host: fakepdf_service_rest_host' }
  it { should contain 'portal_endpoint: fakeportal_endpoint' }
  it { should contain 'ELIS_PASSWORD: fakeelis_password' }
  it { should contain 'local_endpoint: fakecallback_url' }
  it { should contain 'saml_idp_host: fakesaml_endpoint_url' }

  its(:content) { should match /saml_idp_cert: |\n\s*fakesamlidp\n\s*line2/ }
  its(:content) { should match /saml_cert: |\n\s*fakesaml_cert\n\s*line2/ }
  its(:content) { should match /saml_private_key: |\n\s*fakesaml_private_key\n\s*line2/ }
end
