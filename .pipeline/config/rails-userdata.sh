#bash shebang is in caller

#export this so init-script.sh gets it
export REPO_NAME=myuscis-sandbox

source /etc/profile

mkdir -p /userdata
cat > /userdata/init-script.sh <<'INITSCRIPT'
#!/bin/bash -ex

chmod 774 /var/log/cloud-init-output.log
chage -d $(date +'%Y-%m-%d') root

date > /userdata/starttime
service nginx stop

az=$(curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${az::-1}

sensitive_stuff=(certPass samlPassword samlPrivateKey basic_auth_password secret_key_base usps_api_key elis_password database_password sales_force_client_secret sales_force_password)
for sensitive_item in ${sensitive_stuff[@]}
do
  #make me binary
  echo ${!sensitive_item} | base64 --decode > /userdata/${sensitive_item}_enc

  #decrypt the blob
  aws kms decrypt --ciphertext-blob fileb:///userdata/${sensitive_item}_enc \
                  --output text \
                  --region ${region} \
                  --query Plaintext | base64 --decode > /userdata/${sensitive_item}
  if [[ ${PIPESTATUS[0]} -ne 0 ]];
  then
    echo Decryption failed failed
    exit 1
  fi
done

cat > /userdata/formattedattributes.json <<CHEFJSON
{
  "run_list": [
    "recipe[ec2_env]",
    "recipe[https_ssl]",
    "recipe[saml_certs]",
    "recipe[sandbox::from_ami]"
  ],

  "myuscis": {
    "app" : {
      "name": "myuscis-sandbox",

      "callback_url" : "${callback_url}",
      "basic_auth_username": "${basic_auth_username}",
      "basic_auth_password": "@basic_auth_password",
      "secret_key_base": "@secret_key_base",
      "usps_api_key": "@usps_api_key",

      "saml_endpoint_url": "${saml_endpoint_url}",
      "portal_endpoint": "${portal_endpoint}",
      "elis_password": "@elis_password",

      "database_host": "localhost",
      "database_username": "${database_username}",
      "database_password": "@database_password",

      "sales_force_endpoint": "${sales_force_endpoint}",      
      "sales_force_client_id": "${sales_force_client_id}",
      "sales_force_client_secret": "@sales_force_client_secret",
      "sales_force_user_name": "${sales_force_user_name}",
      "sales_force_password": "@sales_force_password"
    },

    "https_ssl": {
      "cert_password": "@certPass"
    },

    "saml": {
      "cert_password": "@samlPassword",
      "idp_object_name": "${samlIdpCertObject}",
      "cert_object_name": "${samlCertObject}",
      "private_key_object_name": "@samlPrivateKey"
    }
  }
}
CHEFJSON

for sensitive_item in ${sensitive_stuff[@]}
do
  ruby -pe "gsub(/@${sensitive_item}/, IO.read('/userdata/${sensitive_item}').chomp)" < /userdata/formattedattributes.json > /userdata/f2.json
  mv /userdata/f2.json /userdata/formattedattributes.json
done

cat > /userdata/solo.rb <<'SOLORB'
file_cache_path  '/userdata/chef/'
cookbook_path ['/userdata/cookbooks-0', '/webapps/myuscis-sandbox/.pipeline/cookbooks']
SOLORB

cat /userdata/formattedattributes.json | awk '{printf("%s",$0)}' > /userdata/attributes.json

chef-solo -l debug -c /userdata/solo.rb -j /userdata/attributes.json

#necessary?
update-alternatives --set ruby /usr/bin/ruby2.1

service nginx restart
INITSCRIPT

bash -ex /userdata/init-script.sh
if [[ $? -eq 0 ]]
then
  status=SUCCESS
else
  status=FAILURE
fi

cat > /userdata/status.json <<STATUSJSON
{"Status" : "${status}", "Reason" : "The application is ready","UniqueId" : "sonar", "Data" : "Done"}
STATUSJSON

date > /userdata/stoptime
