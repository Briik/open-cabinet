#!/bin/bash -ex
set -o pipefail

export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

gem install myuscis-common-pipeline-0.0.30.gem

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region pipeline_instance_id GIT_SHA'

###################################################################

#tie into a build parameter in the job?
target_env=DEV

export AWS_REGION=${region}

set_pipeline_property --key targetEnv \
                      --value ${target_env}

set_or_create_rails_secret --target-env ${target_env^^}

set_pipeline_property --key sandbox_revision \
                      --value ${GIT_SHA}

.pipeline/deploy-sandbox.sh

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value create-acc-environment