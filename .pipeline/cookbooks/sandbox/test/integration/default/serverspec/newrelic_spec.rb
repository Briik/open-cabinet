require 'serverspec'

describe file('/webapps/myuscis-sandbox/config/newrelic.yml') do
  it { should be_file }
  it { should contain 'monitor_mode: true' }
  it { should contain('Sandbox (Unknown)').from(/^production:.*/).to(/^\s*$/) }
  it { should contain "license_key: 'aa6e9eae80fbdde154fcc01c95241c60671a7220'" }
  it { should_not contain /^\s*proxy_host/ }
  it { should_not contain /^\s*proxy_port/ }
end