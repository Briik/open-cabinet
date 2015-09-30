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

confirm_env_vars_available 'sdb_domain region pipeline_instance_id configStore configStorePass'

###################################################################

function run_local_acceptance_tests {
  export RAILS_ENV=test

  bundle exec rake db:drop db:create db:migrate

  bundle exec rake test:integration

  bundle exec rake cucumber \
    CUCUMBER_OPTS="--format json --out ${test_result_dir}/local_acceptance_test_result.json --format pretty"
}

function create_secrets {
  set +x

  cat <<SECRETS > secret.values
environment: test
db_host: fake
db_un: fake
db_pw: fake
un: $(get_inventory_parameter --parameter basicAuthUsername)
pw: $(get_inventory_parameter --parameter basicAuthPassword)
secret_key_base: $(bundle exec rake secret | tail -1)
portal_endpoint: fake
SECRETS
  set -x

  render_template --template-path '.pipeline/config/secrets.yml.erb' \
                  --output-path 'config/secrets.yml' \
                  --values-path secret.values

  rm secret.values
}

#############################################################

cp config/database.yml.sample config/database.yml

bundle install --jobs 4 --without development --retry 10
bundle update --jobs 4 --retry 10

create_secrets

prepare_test_result_dir

run_local_acceptance_tests

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value integration-test

set_pipeline_property --key production_candidate \
                      --value true