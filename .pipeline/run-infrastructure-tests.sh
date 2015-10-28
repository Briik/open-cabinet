#!/bin/bash -ex

#when all pipelines have updated bundler, this can happens at the user level
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

export vpc_label=${name_of_jenkins_stack/-*/}
bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region pipeline_instance_id'

###################################################################

sandbox_stack_name=$(get_pipeline_property --key sandbox_rails_stack_name)
sandbox_elb_url=$(get_elb_name --region ${region} --stackname ${sandbox_stack_name})
sandbox_launch_configuration=$(get_launch_configuration_name --region ${region} --stackname ${sandbox_stack_name})

asg_name=$(get_asg_name --region ${region} --stackname ${sandbox_stack_name})
instance_private_ip=$(get_private_ips_from_asg --asg-name ${asg_name} --region ${region})


  bundle install --jobs 4 --retry 10

  export SANDBOX_STACK_NAME=${sandbox_stack_name}
  export ELB_NAME=${sandbox_elb_url}
  export LAUNCH_CONFIGURATION_NAME=${sandbox_launch_configuration}

  export TARGET_HOST_SSH_KEY_PATH=/var/lib/jenkins/.ssh/${name_of_jenkins_stack}.pem
  export TARGET_HOST="${instance_private_ip}"

  # commenting out to make sure the instance stands up
  bundle exec rake spec RAILS_ENV=test
pushd .pipeline/config
  #times=(1 2)

  #for time in ${times[@]}
  #do
  #  sleep 20
  #done
popd