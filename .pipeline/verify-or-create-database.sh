#!/bin/bash -ex

if [[ -z ${vpc_label} ]]; then echo must set vpc_label; exit 1; fi

#when all pipelines have updated bundler, this can happens at the user level
gem update bundler
#bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.myuscispilot.com/nexus/content/repositories/rubygemsproxy/
#bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.myuscispilot.com/nexus/content/repositories/rubygemsproxy/

#bundle install --jobs 4 \
#               --gemfile=$(dirname $0)/Gemfile \
#               --retry 10

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region target_env pipeline_instance_id configStore configStorePass'

####################################

#discover_vpc_configuration
app-name=open-cabinet-RDS

rds_stack_name_inventory_key=$(compute_stack_name --vpc-label ${vpc_label} \
                                                  --target-env ${target_env} \
                                                  --app-name ${app-name})

rds_stack_name=$(get_inventory_parameter --parameter ${rds_stack_name_inventory_key} --blank-ok)

rds_stack_exists=$(is_existing_stack --region ${region} --stackname "${rds_stack_name}")

#can come from the acceptance-tested-trigger.sh script....
open-cabinet_db_snapshot_identifier=$(get_pipeline_property --key openCabinetDbSnapshotIdentifier)

if [[ ${rds_stack_exists} == false ]] || [[ -n "${open-cabinet_db_snapshot_identifier}" ]] ;
then
  rds_stack_name=$(compute_stack_name --vpc-label ${vpc_label} \
                                      --target-env ${target_env} \
                                      --app-name ${app-name} \
                                      --suffix $(generate_timestamp))

  #database_storage=$(compute_db_allocated_storage formsDbStorage ${open-cabinet_db_snapshot_identifier})
  database_storage=5

  db_subnet_group_id=$(get_inventory_parameter --parameter ${vpc_id}_db_subnet_group)
  echo "Using DB Subnet Group: '${db_subnet_group_id}'"

  #db_instance_size=$(get_pipeline_property --key dbInstanceSize)
  #db_instance_size=${db_instance_size:-db.m3.medium}
  db_instance_size=db.m3.medium

  #parameter_group_name=$(get_inventory_parameter --parameter rds_parameter_group_name_postgres_9_4 --blank-ok)
  #parameter_group_name="${parameter_group_name:-default.postgres9.4}"
  parameter_group_name=default.postgres9.4

  cfndsl .pipeline/config/rds-cfndsl.rb > .pipeline/config/rds.json

  echo "Creating RDS CFN stack, ${rds_stack_name}, with db instance size ${db_instance_size}"
  aws cloudformation create-stack \
      --stack-name "${rds_stack_name}" \
      --template-body file://.pipeline/config/rds.json \
      --region ${region} \
      --disable-rollback \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey="DBInstanceIdentifier",ParameterValue="${rds_stack_name}" \
        ParameterKey="DBSnapshotIdentifier",ParameterValue="${forms_db_snapshot_identifier}" \
        ParameterKey="DBUsername",ParameterValue=db_user \
        ParameterKey="DBPassword",ParameterValue=db_password \
        ParameterKey="DBClass",ParameterValue="${db_instance_size}" \
        ParameterKey="DBName",ParameterValue=open-cabinet-db \
        ParameterKey="DBAllocatedStorage",ParameterValue="${database_storage}" \
        ParameterKey="VpcId",ParameterValue=${vpc_id} \
        ParameterKey="DBSubnetGroupID",ParameterValue="${db_subnet_group_id}" \
        ParameterKey="DBParameterGroupName",${parameter_group_name}

  do_retry "monitor_stack --stack ${rds_stack_name} --region ${region}"

  source_db_instance_id=$(get_stack_resource_id --region ${region} \
                                                --stackname ${rds_stack_name} \
                                                --resourcename open-cabinet-db)

  echo "RDS Stack=${rds_stack_name}, db instance id = ${source_db_instance_id}"

  set_pipeline_property --key source_db_instance_id \
                        --value ${source_db_instance_id}

  set_inventory_parameter --parameter ${rds_stack_name_inventory_key} \
                          --value ${rds_stack_name}

else
  echo "Permanent RDS, ${rds_stack_name}, already exists for ${target_env}"
fi

set_pipeline_property --key forms_rds_stack_name \
                      --value ${rds_stack_name}