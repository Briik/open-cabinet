#bash shebang is in caller

#export this so init-script.sh gets it
export REPO_NAME=myuscis-sandbox

source /etc/profile
source /etc/profile.d/rvm.sh

rvm --default use 2.2.1

mkdir -p /userdata
cat > /userdata/init-script.sh <<'INITSCRIPT'
#!/bin/bash -ex

chmod 774 /var/log/cloud-init-output.log
chage -d $(date +'%Y-%m-%d') root

date > /userdata/starttime
service nginx stop

az=$(curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${az::-1}

sensitive_stuff=(certPass basic_auth_password secret_key_base database_password)
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
    "recipe[sandbox::from_ami]"
  ],

  "myuscis": {
    "app" : {
      "name": "open-cabinet",

      "un": "${basic_auth_username}",
      "pw": "@basic_auth_password",
      "secret_key": "@secret_key_base",
      "db_host": "${database_host}",
      "db_un": "${database_username}",
      "db_pw": "@database_password"
    },

    "https_ssl": {
      "cert_password": "@certPass"
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
cookbook_path ['/userdata/cookbooks-0', '/webapps/open-cabinet/.pipeline/cookbooks']
SOLORB

cat /userdata/formattedattributes.json | awk '{printf("%s",$0)}' > /userdata/attributes.json

chef-solo -l debug -c /userdata/solo.rb -j /userdata/attributes.json

#necessary?
#update-alternatives --set ruby /usr/bin/ruby2.1

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
