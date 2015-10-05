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
function create_secrets {
  set +x
  stackname=$(get_pipeline_property --key open_cabinet_rds_stack_name)
  echo ${stackname}
  hostname=$(get_db_hostname --region ${region} --stackname ${stackname})
  echo ${hostname}
  cat <<SECRETS > secret.values
  secret_key_base: ${secret_key_base}
  db_host: $(get_db_hostname --region ${region} --stackname $(get_pipeline_property --key open_cabinet_rds_stack_name))
  db_un: dbuser
  db_pw: dbpassword
  un: user
  pw: password
  import_key: tQ2ILy9FhJedWF2iH09nwIKdNV7eEhMXsz4c8zef
SECRETS
  set -x

  render_template --template-path '.pipeline/config/secrets.yml.erb' \
                  --output-path 'config/secrets.yml' \
                  --values-path secret.values

  rm secret.values
}

function run_local_acceptance_tests {
  export RAILS_ENV=test

  #bundle exec rake db:drop db:create db:migrate

  bundle exec rake cucumber \
    CUCUMBER_OPTS="--format json --out ${test_result_dir}/local_acceptance_test_result.json --format pretty"
}

#############################################################

bundle install --jobs 4 --without development --retry 10
bundle update --jobs 4 --retry 10

prepare_test_result_dir

export secret_key_base=$(get_inventory_parameter --parameter secret_key_base)
create_secrets
run_local_acceptance_tests

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value integration-test

set_pipeline_property --key production_candidate \
                      --value true