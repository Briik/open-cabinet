require 'serverspec'

describe file('/etc/nginx/nginx.conf') do
  it { should be_file }
  its(:content) { should match /env JAVA_HOME=\/usr\/lib\/jvm\/jdk1\.8\.0_\d+;/ }
  it { should contain('root /webapps/myuscis-sandbox/public;') }
end