#!/bin/bash -elx
set -o pipefail

#export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

time bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

gem install myuscis-common-pipeline-0.0.30.gem

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region pipeline_instance_id configStore configStorePass githubpem GIT_SHA'

###################################################################
set_inventory_parameter --parameter sandbox_database_un --value dbuser
set_inventory_parameter --parameter sandbox_database_pass --value dbpassword
set_inventory_parameter --parameter base_myuscis_ami_id --value ami-61a2dc04
set_inventory_parameter --parameter vpc --value ${vpc}
set_inventory_parameter --parameter privateSubnetA --value subnet-059a8d72

time berks vendor --berksfile .pipeline/config/packer/Berksfile .pipeline/cookbooks-vendor/

### NOTE!!!!!! IF YOU ARE PASSING IN SOMETHING SENSITIVE HERE!!!!!!!
### BE SURE IT IS AT LEAST ENCRYPTED IN THE IMAGE OR REMOVED BEFORE BAKING THE IMAGE!!!!!!
### ANYTHING SENSITIVE SHOULD BE WIRED IN AT STARTUP.  IDEALLY CREDENTIALS CHANGE ALL THE TIME TOO!!!
### SO BAKING THEM IN MEANS ROTATION WILL CAUSE FAILURES.....
time /opt/packer/packer -machine-readable build \
       -var "githubpem=${githubpem}" \
       -var "database_password=$(get_inventory_parameter --parameter sandbox_database_pass)" \
       \
       -var "hardened_base_ami=$(get_inventory_parameter --parameter base_myuscis_ami_id)" \
       -var "database_username=$(get_inventory_parameter --parameter sandbox_database_un)" \
       -var "vpc_id=$(get_inventory_parameter --parameter vpc)" \
       -var "subnet_id=$(get_inventory_parameter --parameter privateSubnetA)" \
       -var "app_git_sha=${GIT_SHA}" \
       -var "new_relic_environment=ACC" \
       -var "gemfile_source=$(discover_gemfile_source)" \
       \
       .pipeline/config/packer/sandbox_ami.json 2>&1 | tee packer.output

#1434651964,amazon-ebs,artifact,0,string,AMIs were created:\n\nus-east-1: ami-b5d32ede
new_ami_id=$(grep 'AMIs were created' packer.output | cut -f 6 -d ',' | cut -f 4 -d ' ')
echo "new sandbox ami id=${new_ami_id}"

set_pipeline_property --key sandbox_amiid \
                      --value ${new_ami_id}

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value create-system-image