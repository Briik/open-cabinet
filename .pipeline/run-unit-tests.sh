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

confirm_env_vars_available 'sdb_domain region pipeline_instance_id'

####################################

bundle install --jobs 4 --retry 10

cp config/secrets.yml.sample config/secrets.yml
#cp config/database.yml.sample config/database.yml

#bundle exec rake db:migrate:reset RAILS_ENV=test
#bundle exec rake test:unit RAILS_ENV=test
bundle exec rspec

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value build

set_pipeline_property --key production_candidate \
                      --value false