require 'serverspec'

describe file('/webapps/myuscis-sandbox/config/database.yml') do
  it { should be_file }
  it { should contain 'username: postgres' }
  it { should contain 'password: fakepassword' }
  it { should contain 'host: localhost' }
  it { should contain 'database: sandbox' }
end