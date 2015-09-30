require 'serverspec'

describe file('/webapps/myuscis-sandbox/config/initializers/0_environment_variables.rb') do
  it { should be_file }
  it { should contain "ENV['disable_ga'] = 'false'" }
  it { should contain "ENV['disable_auth'] = 'false'" }
  it { should contain "ENV['disable_newrelic'] = 'false'" }

end
