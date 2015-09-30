require 'serverspec'

set :backend, :exec

require 'serverspec-aws-resources'

necessary_environment_vars = %w{ELB_NAME SANDBOX_STACK_NAME LAUNCH_CONFIGURATION_NAME}

necessary_environment_vars.each do |necessary_environment_var|
  fail("#{necessary_environment_var} not available") unless ENV[necessary_environment_var]
end