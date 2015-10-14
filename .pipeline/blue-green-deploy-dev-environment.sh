#!/bin/bash -ex

export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

gem install myuscis-common-pipeline-0.0.30.gem

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'region pipeline_instance_id configStore configStorePass'

###################################################################

rails_stack_name=$(get_pipeline_property --key sandbox_rails_stack_name)

target_env=$(get_pipeline_property --key targetEnv)

set_inventory_parameter --parameter domain --value "development.com"
set_inventory_parameter --parameter ${target_env}_subdomainName --value "development"

subdomain_name=$(get_inventory_parameter --parameter ${target_env}_subdomainName)

route53switch-elb --subdomain "${subdomain_name}.sandbox" \
                  --hostedzone $(get_inventory_parameter --parameter domain) \
                  --region ${region} \
                  --stackname ${rails_stack_name}

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value dev_bluegreen
