#!/bin/bash -ex
set -o pipefail

export vpc_label=${name_of_jenkins_stack/-*/}

#when all pipelines have updated bundler, this can happens at the user level
bundler config --local mirror.http://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/
bundler config --local mirror.https://rubygems.org http://${vpc_label,,}-nexus.${domain}/nexus/content/repositories/rubygemsproxy/

bundle install --jobs 4 \
               --gemfile=$(dirname $0)/Gemfile \
               --retry 10

source $(gem contents myuscis-common-pipeline | grep common-bash-functions)

confirm_env_vars_available 'sdb_domain region pipeline_instance_id name_of_jenkins_stack certPass'

###################################################################

discover_vpc_configuration

target_env=$(get_pipeline_property --key targetEnv)

rails_stack_name=$(compute_canonical_stack_name ${vpc_label} ${target_env} Sandbox-Rails-ASG build_sandbox_index)

##in case the stack fails, store the stack name so that we can download the log file from it.
set_pipeline_property --key failedInstanceName \
                      --value ${rails_stack_name}

cfndsl .pipeline/config/rails-cfndsl.rb > .pipeline/config/rails.json

#fix me for prod
encryption_key_alias=alias/PubDev-pipeline

#WARNING!!!!!!!!
#AS YOU ARE PASSING IN SENSITIVE CREDENTIALS HERE - BE SURE TO ENCRYPT THEM!!!!!
aws cloudformation create-stack \
  --stack-name ${rails_stack_name} \
  --template-body file://.pipeline/config/rails.json \
  --region ${region} \
  --disable-rollback \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=secretKeyBase,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_pipeline_property --key railsSecret)) \
    ParameterKey=authPass,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter basicAuthPassword)) \
    ParameterKey=databasePass,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter sandbox_database_pass)) \
    ParameterKey=uspsApiKey,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter usps_api_key)) \
    ParameterKey=elisPassword,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter elis_password)) \
    ParameterKey=certPass,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext ${certPass}) \
    ParameterKey=sfClientSecret,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext "$(get_inventory_parameter --parameter ${target_env}_sales_force_client_secret --blank-ok)") \
    ParameterKey=sfPassword,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext "$(get_inventory_parameter --parameter ${target_env}_sales_force_password --blank-ok)") \
    ParameterKey=samlPassword,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter ${vpc_id}_saml_pw)) \
    ParameterKey=samlPrivateKey,ParameterValue=$(encrypt_with_kms --key-arn ${encryption_key_alias} --plaintext $(get_inventory_parameter --parameter ${vpc_id}_saml_private_key)) \
    \
    ParameterKey=imageId,ParameterValue=$(get_pipeline_property --key sandbox_amiid) \
    ParameterKey=InstanceKeyPair,ParameterValue=${name_of_jenkins_stack} \
    ParameterKey=VpcId,ParameterValue=${vpc_id} \
    ParameterKey=vpcCidr,ParameterValue=${vpc_cidr} \
    ParameterKey=ASGSubnets,ParameterValue="${private_subnet_a}" \
    ParameterKey=ASGSubnetAZs,ParameterValue=$(get_subnet_azs --subnet-csv ${private_subnet_a}) \
    ParameterKey=ELBSubnets,ParameterValue=$(get_inventory_parameter --parameter publicSubnet) \
    ParameterKey=KeyArn,ParameterValue=$(discover_key_arn_for_alias --alias-name ${encryption_key_alias}) \
    \
    ParameterKey=databaseHost,ParameterValue=localhost \
    ParameterKey=databaseUser,ParameterValue=$(get_inventory_parameter --parameter sandbox_database_un) \
    ParameterKey=authUser,ParameterValue=$(get_inventory_parameter --parameter basicAuthUsername) \
    ParameterKey=samlEndpointUrl,ParameterValue=$(get_saml_url --target-env development --vpc ${vpc_id}) \
    ParameterKey=samlIdpCertObject,ParameterValue=$(get_inventory_parameter --parameter ${vpc_id}_saml_idp_cert) \
    ParameterKey=samlCertObject,ParameterValue=$(get_inventory_parameter --parameter ${vpc_id}_saml_cert) \
    ParameterKey=callbackUrl,ParameterValue=$(get_saml_callback_url --target-env $(discover_subdomain_name) --vpc ${vpc_id}) \
    ParameterKey=portalEndpoint,ParameterValue=$(discover_portal_endpoint ${target_env}) \
    ParameterKey=sfEndpoint,ParameterValue="$(get_inventory_parameter --parameter ${target_env}_sales_force_endpoint)" \
    ParameterKey=sfClientId,ParameterValue="$(get_inventory_parameter --parameter ${target_env}_sales_force_client_id)" \
    ParameterKey=sfUserName,ParameterValue="$(get_inventory_parameter --parameter ${target_env}_sales_force_user_name)" \
    \
  --tags \
    Key=StackType,Value=DEV \
    Key=Application,Value=Sandbox \
    Key=application-instance-guid,Value="$(generate_stack_uuid_for_zombie_sweeper)" \
    Key=vpcIdentifier,Value=${vpc_label}

do_retry "monitor_stack --stack ${rails_stack_name} --region ${region}"

set_pipeline_property --key sandbox_url \
                      --value $(get_elb_url --region ${region} --stackname ${rails_stack_name})

set_pipeline_property --key sandbox_rails_stack_name \
                      --value ${rails_stack_name}

set_pipeline_property --key failedInstanceName \
                      --value ''