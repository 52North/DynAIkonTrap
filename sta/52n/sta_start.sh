#!/bin/bash -e
#
# Copyright 2021 Secure Dimensions GmbH
# Copyright 2021 52°North Spatial Information Research GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


if test "$#" -ne 1; then
    echo "USAGE: $0 <sta_url>" 
    exit -1
fi

sta_url=$1

scope="openid profile email offline_access org.52north.demo.cos4cloud:staplus"
software_id=$(ifconfig | grep ether | head -1 | xargs | cut -d " " -f 2 | md5sum )
registration=$(cat -s << EOF
{
    "redirect_uris": [
        "https://cos4cloud.demo.secure-dimensions.de/camera-trap-app"

    ],
    "grant_types": [
        "authorization_code",
        "refresh_token"
    ],
    "response_types": [
        "code",
        "id_token token",
        "refresh_token"
    ],
    "client_name": "Cos4Cloud Camera Trap App",
    "logo_uri": "https://gitlab.dynaikon.com/uploads/-/system/project/avatar/30/logo_avatar.png",
    "scope": "$scope",
    "contacts": [],
    "tos_uri": "https://gitlab.dynaikon.com/dynaikontrap/dynaikontrap",
    "software_id": "$software_id",
    "software_version": "0.1"
}
EOF
)

app=$(curl --silent -X POST -H "Content-Type:application/x-www-form-urlencoded" --data "$registration" "https://www.authenix.eu/oauth/register")
echo $app | jq '.'
client_id=$(echo $app | jq -r '.client_id')
client_secret=$(echo $app | jq -r '.client_secret')
scope=$(echo $app | jq -r '.scope')
client_secret_expires_at=$(echo $app | jq '.client_secret_expires_at')

echo ""
echo "Open a Web Browser with the following URL"
echo "https://cos4cloud.demo.secure-dimensions.de/camera-trap-app"
echo "and use the following 'client_id' as input:"
echo $client_id
echo "-- OR --"
echo "Open the following URL in a Web Browser and copy the Authorization Code as input"
echo ""
echo "https://www.authenix.eu/oauth/authorize?response_type=code%20id_token&client_id=$client_id&redirect_uri=https%3A%2F%2Fcos4cloud.demo.secure-dimensions.de%2Fcamera-trap-app&scope=$scope&state=xyz&nonce=123"
echo ""
read -p "please provide the authorization_code: " authorization_code

token=$(curl --silent -X POST \
   -H "Content-Type:application/x-www-form-urlencoded" \
   -d "client_id=$client_id" \
   -d "client_secret=$client_secret" \
   -d "grant_type=authorization_code" \
   -d "response_type=token refresh_token" \
   -d "code=$authorization_code" \
   -d "redirect_uri=https://cos4cloud.demo.secure-dimensions.de/camera-trap-app" \
   --data-urlencode "scope=$scope" \
 'https://www.authenix.eu/oauth/token')

access_token=$(echo $token | jq -r '.access_token')
refresh_token=$(echo $token | jq -r '.refresh_token')
expires_in=$(echo $token | jq '.expires_in')
now=$(date +%s)
expires=$(($expires_in + $now))
echo access_token: $access_token
echo refresh_token: $refresh_token
echo expires: $expires

client_credentials=$(echo -n "$client_id:$client_secret" | base64 -w 0)
token_info=$(curl --silent -X POST \
   -H "Authorization:Basic $client_credentials" \
   -H "Content-Type:application/x-www-form-urlencoded" \
   -d "token=$access_token" \
 'https://www.authenix.eu/oauth/tokeninfo')
sub=$(echo $token_info | jq -r '.sub')
#echo $sub

#run the setup
./sta_setup.sh $sub $access_token $sta_url

trap_home="../../DynAIkonTrap/"
video_path=$(cat "$trap_home/settings.json" | jq -r '.output.path')
echo "start preprocessing data from "${video_path:=$trap_home}""

while true; do 
  now=$(date +%s)
   if [ $client_secret_expires_at -lt $((now - 30)) ]; then
     app=$(curl --silent -X POST -H "Content-Type:application/x-www-form-urlencoded" --data "$registration" "https://www.authenix.eu/oauth/register")
     client_id=$(echo $app | jq -r '.client_id')
     client_secret=$(echo $app | jq -r '.client_secret')
     scope=$(echo $app | jq -r '.scope')
     client_secret_expires_at=$(echo $app | jq '.client_secret_expires_at')
   fi

   if [ $expires -lt $(($now - 30)) ]; then
    echo "refreshing access_token..."
    token=$(curl --silent -X POST \
   -H "Content-Type:application/x-www-form-urlencoded" \
   -d "client_id=$client_id" \
   -d "client_secret=$client_secret" \
   -d "grant_type=refresh_token" \
   -d "refresh_token=$refresh_token" \
   -d "response_type=token refresh_token" \
   -d "scope=$scope" \
 'https://www.authenix.eu/oauth/token')
 
  echo "...done"
   
 access_token=$(echo $token | jq -r '.access_token')
 refresh_token=$(echo $token | jq -r '.refresh_token')
 expires_in=$(echo $token | jq '.expires_in')
 now=$(date +%s)
 expires=$(($expires_in + $now))

  #else
    #echo reuse existing access_token
  fi
  for f in "$video_path/*.vtt"; do 
    if test -f $f; then 
      fname=$(basename $f .vtt)
      file="$video_path/$fname"
      echo "processing file: $fname with access_token: $access_token for sta_url: $sta_url"
      ./sta_feeder.sh $file $access_token $sta_url
      code=$?;
      if [ $code -ne 0 ]; then
        echo error - skipping file $fname;
      else
        mv $file.vtt $file.vtt_; 
      fi
    #else
      #echo "no files to process - waiting 10 seconds..."
    fi 
  done; 
  sleep 10; 
done

