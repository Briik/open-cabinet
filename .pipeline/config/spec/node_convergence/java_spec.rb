require 'spec_helper_ssh'

describe command('java -version') do
  its(:stderr) { should match /java version "1\.8\.0_51"/}
end