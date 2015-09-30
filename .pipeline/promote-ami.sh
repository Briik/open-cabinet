#!/bin/bash -exl

export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region pipeline_instance_id configStore configStorePass'

###################################################################

sandbox_ami_id=$(get_pipeline_property --key sandbox_amiid)

SHA=$(get_pipeline_property --key SHA)

promote_revision=$(should_promote_revision ${SHA} acceptance-tested-sandbox-revision)

if [ "${promote_revision}" == true ]
then
  set_inventory_parameter --parameter acceptance-tested-sandbox-revision \
                          --value ${SHA}
fi

set_inventory_parameter --parameter ami-sandbox-${SHA} \
                        --value ${sandbox_ami_id}

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value promote-ami
