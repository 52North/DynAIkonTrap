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

. ../sta.config

vtt_file=$1.vtt
mp4_file=$1.mp4
dir_name=$(dirname $vtt_file)

bearer_auth="Bearer $2"
sta_url=$3

# read the ids
foi_id=$(jq -r '.foi_id' sta_setup_ids.json)
ds_imagery_id=$(jq -r '.datastream_ids.imagery' sta_setup_ids.json)
ds_taxon_id=$(jq -r '.datastream_ids.taxon' sta_setup_ids.json)
ds_env_temp_id=$(jq -r '.datastream_ids.temperature' sta_setup_ids.json)
ds_env_humidity_id=$(jq -r '.datastream_ids.humidity' sta_setup_ids.json)
ds_env_pressure_id=$(jq -r '.datastream_ids.pressure' sta_setup_ids.json)
ds_env_brightness_id=$(jq -r '.datastream_ids.brightness' sta_setup_ids.json)
license_cc_by_nc_sa_id=$(jq -r '.license_cc_by_nc_sa_id' sta_setup_ids.json)

now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# parse date and time
date=$(echo $vtt_file | cut -d '_' -f 1 | tr -d $dir_name | tr -d "/" )
time=$(sed '/^$/d' $vtt_file | cut -d '@' -f 2 -s)
datetime=$date'T'$time
#echo $datetime

# parse sensorboard data
data=($(sed '/^$/d' $vtt_file | tail -n 1 | awk '{ print $2; print $5; print $8; print $11}'))
temperature=${data[0]//?}
relative_humidity=${data[1]//?}
brightness=${data[2]//?}
pressure=${data[3]//?}

# TODO
species_guess="Oh look, it's a rabbit!"

echo "upload the video observation"
obs_camera_id=$(uuidgen)
obs_taxon_id=$(uuidgen)

observation_camera=$(cat -s << EOF
{
    "@iot.id": "$obs_camera_id",
    "result": "",
    "phenomenonTime": "$datetime",
    "resultTime": "$now",
    "Datastream": {
      "@iot.id": "$ds_imagery_id"
    },
    "FeatureOfInterest": {
      "@iot.id": "$foi_id"
    }
}
EOF
)

echo $observation_camera
#exit

echo "uploading Observation Imagery..."
status=$(curl -w "%{http_code}" -H "Authorization: $bearer_auth" --connect-timeout 10 --request POST --form "body=$observation_camera;type=application/json" --form "file=@$mp4_file;type=video/mp4" $sta_url/Observations)
code=$?;
echo $code;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create Observation - HTTP status code: $status
    exit -1
else
    echo "...done"
fi

observation_taxon=$(cat -s << EOF
{
    "@iot.id": "$obs_taxon_id",
    "result": "$species_guess",
    "phenomenonTime": "$datetime",
    "resultTime": "$now",
    "Datastream": {
        "@iot.id": "$ds_taxon_id"
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

trap_event_data_group=$(cat -s << EOF
{
    "name": "Camera Trap Identification",
    "description": "All observations and relations for the camera trap event on $datetime",
    "created": "$now",
    "runtime": "$datetime/$now",
    "License": {
        "@iot.id": "$license_cc_by_nc_sa_id"
    },
    "ObservationRelations": [
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
        { "@iot.id": "$obs_camera_id" },
        { "@iot.id": "$obs_taxon_id" },
        {
            "result": ${temperature:=-999},
            "phenomenonTime": "$datetime",
            "resultTime": "$now",
            "Datastream": {
                "@iot.id": "$ds_env_temp_id"
            },
            "FeatureOfInterest": {
                "@iot.id": "$foi_id"
            }
        },
        {
            "result": ${pressure:=-999},
            "phenomenonTime": "$datetime",
            "resultTime": "$now",
            "Datastream": {
                "@iot.id": "$ds_env_pressure_id"
            },
            "FeatureOfInterest": {
                "@iot.id": "$foi_id"
            }
        },
        {
            "result": ${humidity:=-999},
            "phenomenonTime": "$datetime",
            "resultTime": "$now",
            "Datastream": {
                "@iot.id": "$ds_env_humidity_id"
            },
            "FeatureOfInterest": {
                "@iot.id": "$foi_id"
            }
        },
        {
            "result": ${brightness:=-999},
            "phenomenonTime": "$datetime",
            "resultTime": "$now",
            "Datastream": {
                "@iot.id": "$ds_env_brightness_id"
            },
            "FeatureOfInterest": {
                "@iot.id": "$foi_id"
            }
        }
    ]
}
EOF
)

# echo "feed observation data... "
echo "uploading ObservationGroup..."
echo $trap_event_data_group
# exit -1

status=$(curl --silent -w "%{http_code}" -H "Authorization: $bearer_auth" --connect-timeout 10 -H "Content-Type: application/json" -X POST --data "$trap_event_data_group" $sta_url/ObservationGroups)
code=$?;
if [ $code -ne 0 -a $code != "201" ]; then
    echo Error: Could not create Group - HTTP status code: $status
    exit -1
else
    echo "...done"
fi

