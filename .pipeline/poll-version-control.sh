#!/bin/bash -ex

export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
gem update bundler
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

gem install myuscis-common-pipeline-0.0.30.gem

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region BUILD_NUMBER'

####################################

timestamp=$(generate_timestamp)
pipeline_instance_id=$(generate_pipeline_instance_id --build-number ${BUILD_NUMBER} \
                                                     --timestamp ${timestamp})

if [[ -z "${revision}" ]]
then
  GIT_SHA=$(git log | head -1 | awk '{ print $2 }')
else
  GIT_SHA=${revision}
fi

set_pipeline_property --key SHA \
                      --value ${GIT_SHA} \
                      --pipeline-instance-id ${pipeline_instance_id}

set_pipeline_property --key started_at \
                      --value ${timestamp} \
                      --pipeline-instance-id ${pipeline_instance_id}

# push instance id into file so we can load it into the environment
echo pipeline_instance_id=${pipeline_instance_id} > environment.txt
echo GIT_SHA=${GIT_SHA} >> environment.txt
