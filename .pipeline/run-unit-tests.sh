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

function create_secrets {
  set +x
  stackname=$(get_pipeline_property --key open_cabinet_rds_stack_name)
  hostname=$(get_db_hostname --region ${region} --stackname ${stackname})
  cat <<SECRETS > secret.values
  secret_key_base: ${secret_key_base}
  database_host: $(get_db_hostname --region ${region} --stackname $(get_pipeline_property --key open_cabinet_rds_stack_name))
  database_username: dbuser
  database_password: dbpassword
  basic_auth_username: user
  basic_auth_password: password
  import_key: tQ2ILy9FhJedWF2iH09nwIKdNV7eEhMXsz4c8zef
SECRETS
  set -x

  render_template --template-path '.pipeline/config/secrets.yml.erb' \
                  --output-path 'config/secrets.yml' \
                  --values-path secret.values

  rm secret.values
}

bundle install --jobs 4 --retry 10

export target_env=development
secret_key_base=d9c69d37907ea27c1970faf75661433eb8ac11e725bece21fc32ca76274c40b0bb404b09548aa7441e1f801a04f10612c1d104b5388d41c525a9012621dcae01
set_inventory_parameter --parameter secret_key_base \
                          --value ${secret_key_base}
export secret_key_base=${secret_key_base}

cp config/environments/development.rb.sample config/environments/development.rb
$(dirname $0)/verify-or-create-database.sh
create_secrets


#bundle exec rake db:migrate:reset RAILS_ENV=test
#bundle exec rake test:unit RAILS_ENV=test
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:drop RAILS_ENV=test
bundle exec rake db:create RAILS_ENV=test
bundle exec rake db:migrate RAILS_ENV=test
bundle exec rspec

set_pipeline_property --key furthest_pipeline_stage_completed \
                      --value build

set_pipeline_property --key production_candidate \
                      --value false