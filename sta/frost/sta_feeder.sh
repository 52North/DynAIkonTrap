#!/bin/bash
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

if test "$#" -ne 3; then
    echo "USAGE: $0 <file> <access_token> <sta_url>" 
    exit -1
fi

vtt_file=$1.vtt
mp4_file=$1.mp4
dir_name=$(dirname $vtt_file)

bearer_auth="Bearer $2"
sta_url=$3
cdn_url="https://cos4cloud.demo.secure-dimensions.de/cdn"

# set the foi ids
foi_cam_id="foi_cam_id"
foi_sb_id="foi_sb_id"
foi_id=$(uuidgen)
# set the datastream ids
ds_imagery_id=$(jq '.datastream_ids[0]' sta_setup_ids.json)
ds_taxon_id=$(jq '.datastream_ids[1]' sta_setup_ids.json)
mds_env_id=$(jq '.multi_datastream_ids[0]' sta_setup_ids.json)
license_cc_by_nc_sa_id=$(jq '.license_cc_by_nc_sa_id' sta_setup_ids.json)
ds_sb_temp_id="ds_sb_temp_id"
ds_sb_pressure_id="ds_sb_pressure_id"
ds_sb_relhum_id="ds_sb_relhum_id"
ds_sb_lum_id="ds_sb_lum_id"

GPS_LON="2.044367"
GPS_LAT="41.485526"
now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

#echo "Photo Datastream Id: " $ds_imagery_id
#echo "Taxon Datastream Id: " $ds_taxon_id
#echo "Env MultiDatastream Id: " $mds_env_id
#echo "FeatureOfInterst Id: " $foi_id

## TODO parse data from file name
date=$(echo $vtt_file | cut -d '_' -f 1 | tr -d $dir_name | tr -d "/" )
# parse time
time=$(sed '/^$/d' $vtt_file | cut -d '@' -f 2 -s)
datetime=$date'T'$time
#echo $datetime

# parse sensorboard data
data=($(sed '/^$/d' $vtt_file | tail -n 1 | awk '{ print $2; print $5; print $8; print $11}'))
temperature=${data[0]}
relative_humidity=${data[1]}
luminance=${data[2]}
pressure=${data[3]}

# TODO
species_guess="Please allow me to introduce myself - I'm a man of wealth and taste - I've been around for a long, long years - Stole million man's soul an faith"

feature_of_interest=$(cat -s << EOF
{
  "@iot.id": "$foi_id",
  "name": "My garden",
  "description": "The north facing part of the property",
  "encodingType": "application/geo+json",
  "feature": {
    "type": "Point",
    "coordinates": [
      $GPS_LON,
      $GPS_LAT
    ]
  }
}
EOF
)

# echo "feed feature of interst... "
#echo $feature_of_interest
#exit
echo "uploading FeatureOfInterest..."
status=$(curl --silent -w "%{http_code}" --connect-timeout 10 -H "Authorization: $bearer_auth" -H "Content-Type: application/json" -X POST --data "$feature_of_interest" $sta_url/FeaturesOfInterest)
code=$?;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create FeatureOfInterest - HTTP status code: $status
    exit -1
else
    echo "...done"
fi

#echo "upload the video observtaion
obs_camera_id=$(uuidgen)
obs_taxon_id=$(uuidgen)

observation_camera=$(cat -s << EOF
{
    "@iot.id": "$obs_camera_id",
    "result": "",
    "phenomenonTime": "$datetime",
    "resultTime": "$now",
    "Datastream": {
      "@iot.id": $ds_imagery_id
    },
    "FeatureOfInterest": {
      "@iot.id": "$foi_id"
    }
}
EOF
)

#echo $observation_camera
#exit
echo "uploading Observation Photo..."
status=$(curl --silent -w "%{http_code}" -H "Authorization: $bearer_auth" --connect-timeout 10 --request POST  --form "observation=$observation_camera;type=application/json" --form "photo=@$mp4_file;type=video/mp4" $sta_url/\$observation)
code=$?;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create Observation Photo - HTTP status code: $status
    exit -1
else
    echo "...done"
fi
#exit

observation_taxon=$(cat -s << EOF
{
    "@iot.id": "$obs_taxon_id",
    "result": "$species_guess",
    "phenomenonTime": "$datetime",
    "resultTime": "$now",
    "Datastream": {
        "@iot.id": $ds_taxon_id
    },
    "FeatureOfInterest": {
        "@iot.id": "$foi_id"
    }
}
EOF
)

#echo $observation_taxon
#exit
echo "uploading Observation Taxon..."
status=$(curl --silent -w "%{http_code}" -H "Authorization: $bearer_auth" --connect-timeout 10 -H "Content-Type: application/json" -X POST --data "$observation_taxon" $sta_url/Observations)
code=$?;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create Observation Taxon - HTTP status code: $status
    exit -1
else
    echo "...done"
fi

trap_event_data=$(cat -s << EOF
{
    "name": "Camera Trap Event",
    "description": "All observations and relations for the camera trap event on $datetime",
    "created": "$now",
    "runtime": "$datetime/$now",
    "License": {"@iot.id": $license_cc_by_nc_sa_id},
    "Relations": [
        {
            "Subject": {
                "@iot.id": "$obs_camera_id"
            },
            "role": "#identifiedBy",
            "namespace": "https://some-ontology.org/",
            "Object": {
                "@iot.id": "$obs_taxon_id"
            }
        }
    ],
    "Observations": [
        {
            "result": ["$temperature","$relative_humidity","$pressure","$luminance"],
            "phenomenonTime": "$datetime",
            "resultTime": "$now",
            "MultiDatastream": {
                "@iot.id": $mds_env_id
            },
            "FeatureOfInterest": {
                "@iot.id": "$foi_id"
            }
        },
        { "@iot.id": "$obs_camera_id" },
        { "@iot.id": "$obs_taxon_id" }
    ]
}
EOF
)

# echo "feed observation data... "
echo "uploading Group..."
status=$(curl --silent -w "%{http_code}" -H "Authorization: $bearer_auth" --connect-timeout 10 -H "Content-Type: application/json" -X POST --data "$trap_event_data" $sta_url/Groups)
code=$?;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create Group - HTTP status code: $status
    exit -1
else
    echo "...done"
fi

