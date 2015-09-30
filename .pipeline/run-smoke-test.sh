#!/bin/bash

url_to_test='https://development.sandbox.myuscispilot.com/sandbox'

times=(1 2 3 4 5 6 7 8 9 10)

for time in ${times[@]}
do
  response=$(curl -o /dev/null --insecure --silent --head --write-out '%{http_code}' ${url_to_test})

  if [[ ${response} == '200' ]]
  then
    echo Smoke test passed with 200 for ${url_to_test}
    exit 0
  else
    echo Smoke test did NOT pass with code: ${response}.   Retrying.....  Debug follows:
    curl --verbose --insecure ${url_to_test}
    sleep 20
  fi
done

echo Smoke test did NOT pass with code: ${response}.  Debug follows:
curl --verbose --insecure ${url_to_test}
exit 2

