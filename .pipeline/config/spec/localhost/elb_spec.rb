require 'spec_helper'

elb_name = ENV['ELB_NAME']

describe elb(elb_name) do
  #it { should have_scheme 'internal' }

  it { should_not have_cross_zone_load_balancing_enabled }

  it { should have_connection_draining_enabled }
  #it { should have_connection_draining_timeout(300) }


  it { should have_number_of_listeners(2) }

  it { should have_listener({port: '80', protocol: 'tcp', instance_port: '80', instance_protocol: 'tcp'}) }

  #no property for test: ['arn:aws:iam::', Ref('AWS::AccountId'), ':server-certificate/myuscis-cert']
  it { should have_listener(port: '443', protocol: 'ssl', instance_port: '443', instance_protocol: 'ssl') }

  it { should have_number_of_security_groups(1) }

  it { should have_ingress_rules [
                                   {port_range: '80..80', protocol: 'tcp', ip_ranges: %w{0.0.0.0/0}},
                                   {port_range: '443..443', protocol: 'tcp', ip_ranges: %w{0.0.0.0/0}}
                                 ] }
  it { should have_egress_rules [
                                   {port_range: '80..80', protocol: 'tcp', ip_ranges: %w{0.0.0.0/0}},
                                   {port_range: '443..443', protocol: 'tcp', ip_ranges: %w{0.0.0.0/0}}
                                 ] }

  #it { should have_health_check_healthy_threshold(3) }
  #it { should have_health_check_unhealthy_threshold(5) }
  #it { should have_health_check_interval(90) }
  it { should have_health_check_timeout(60) }

  #it { should have_health_check_target('HTTPS:443/is_it_up') }

  it { should have_availability_zone_names(%w{us-east-1b})}
  it { should have_number_of_availability_zones(1) }

  # it { should have_tags [{ Key: 'client', Value: 'myuscis' }] }

end