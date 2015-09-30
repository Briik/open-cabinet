require 'spec_helper'

asg_group_name = ENV['SANDBOX_STACK_NAME']
elb_name = ENV['ELB_NAME']
launch_configuration_name = ENV['LAUNCH_CONFIGURATION_NAME']

describe auto_scaling_group(asg_group_name) do

  it { should have_min_size(1) }
  it { should have_max_size(1) }
  it { should have_desired_capacity(1) }

  it { should have_load_balancers([elb_name]) }
  it { should have_availability_zone_names(%w{us-east-1b}) }

  it { should have_health_check_grace_period(300) }

  #HealthCheckType 'ELB'

  #check the scaling policies
end

describe launch_configuration(launch_configuration_name) do
  it { should have_instance_type('m3.medium') }
end