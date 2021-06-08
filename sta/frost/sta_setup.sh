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
    echo "USAGE: $0 <auth_id> <access_token> <sta_url>" 
    exit
fi

if test -f "sta_setup_ids.json"; then
    echo "configuration already exists."
    exit
else
    
    AUTH_ID=$1
    ACCESS_TOKEN=$2
    STA_URL=$3
    GPS_LON="2.044367"
    GPS_LAT="41.485526"
    PROJECT_ID=`uuidgen`
    THING_1_ID=`uuidgen`
    THING_2_ID=`uuidgen`
    CC0_ID=`uuidgen`
    CC_BY_ID=`uuidgen`
    CC_BY_NC_ID=`uuidgen`
    CC_BY_NC_SA_ID=`uuidgen`
    CC_BY_SA_ID=`uuidgen`
    DS_1_ID=`uuidgen`
    DS_2_ID=`uuidgen`
    MDS_1_ID=`uuidgen`
    DATE_TIME_NOW=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

sta_setup_ids=$(cat -s << EOF
{
    "auth_id": "$AUTH_ID",
    "project_id": "$PROJECT_ID",
    "thing_ids": [
        "$THING_1_ID",
        "$THING_2_ID"
    ],
    "license_cc_zero_id": "$CC0_ID",
    "license_cc_by_id": "$CC_BY_ID",
    "license_cc_by_nc_id": "$CC_BY_NC_ID",
    "license_cc_by_nc_sa_id": "$CC_BY_NC_SA_ID",
    "license_cc_by_sa_id": "$CC_BY_SA_ID",
    "datastream_ids": [
        "$DS_1_ID",
        "$DS_2_ID"
    ],
    "multi_datastream_ids": ["$MDS_1_ID"]
}
EOF
)
    

fi

sta_setup_data=$(cat -s << EOF
{
    "party": {
        "@iot.id": "$AUTH_ID",
        "name": "Long John Silver Citizen Scientist",
        "description": "The opportunistic pirate by Robert Louis Stevenson",
        "nickName": "Long John Silver",
        "role": "individual",
        "authId": "$AUTH_ID"
    },
    "project": {
        "@iot.id": "$PROJECT_ID",
        "name": "Species Detection by DynAIkon Camera Trap",
        "description": "The automatic detection of species by all participating camera traps",
        "url": "https://cos4cloud.demo.secure-dimensions.de/projects/cameratrap",
        "termsOfUse": "Please do not upload sensitive information!.",
        "privacyPolicy": "This project stores the user's globally unique identifier that cannot be used to retrieve personal information.",
        "created": "2021-05-28T08:12:00Z",
        "classification": "public"
    },
    "things": {
        "raspberry_pi": {
            "@iot.id": "$THING_1_ID",
            "name": "Raspberry Pi 4 B, 4x 1,5 GHz, 4 GB RAM, WLAN, BT",
            "description": "Raspberry Pi 4 Model B is the latest product in the popular Raspberry Pi range of computers",
            "properties": {
                "CPU": "1.4GHz",
                "RAM": "4GB"
            },
            "Locations": [
                {
                    "name": "My Garden",
                    "description": "The north facing part of the property",
                    "encodingType": "application/geo+json",
                    "location": {
                        "type": "Point",
                        "coordinates": [
                            $GPS_LON,
                            $GPS_LAT
                        ]
                    },
                    "properties": {
                        "city": "Munich",
                        "countryCode": "DE"
                    }
                }
            ]
        },
        "env_board": {
            "@iot.id": "$THING_2_ID",
            "name": "Universal Environment Board",
            "description": "todo",
            "properties": {
                "Temperature": "temperature on board",
                "Humidity": "air humidity",
                "Pressure": "air pressure sensor",
                "GPS": "GPS unit available"
            },
            "Locations": [
                {
                    "name": "My Garden",
                    "description": "The north facing part of the property",
                    "encodingType": "application/geo+json",
                    "location": {
                        "type": "Point",
                        "coordinates": [
                            $GPS_LON,
                            $GPS_LAT
                        ]
                    },
                    "properties": {
                        "city": "Munich",
                        "countryCode": "DE"
                    }
                }
            ]
        }
    },
    "licenses": {
        "cc_zero": {
            "@iot.id": "$CC0_ID",
            "name": "CC0",
            "definition": "https://creativecommons.org/publicdomain/zero/1.0/",
            "description": "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication",
            "logo": "https://mirrors.creativecommons.org/presskit/buttons/88x31/png/cc-zero.png"
        },
        "cc_by": {
            "@iot.id": "$CC_BY_ID",
            "name": "CC BY 3.0",
            "definition": "https://creativecommons.org/licenses/by/3.0/de/deed.en",
            "description": "The Creative Commons Attribution license",
            "logo": "https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by.png"
        },
        "cc_by_nc": {
            "@iot.id": "$CC_BY_NC_ID",
            "name": "CC BY-NC 3.0",
            "definition": "https://creativecommons.org/licenses/by-nc/3.0/de/deed.en",
            "description": "The Creative Commons Attribution-NonCommercial license",
            "logo": "https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc.png"
        },
        "cc_by_sa": {
            "@iot.id": "$CC_BY_SA_ID",
            "name": "CC BY-SA 3.0",
            "definition": "https://creativecommons.org/licenses/by-sa/3.0/de/deed.en",
            "description": "The Creative Commons Attribution & Share-alike license",
            "logo": "https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-sa.png"
        },
        "cc_by_nc_sa": {
            "@iot.id": "$CC_BY_NC_SA_ID",
            "name": "CC BY-NC-SA 3.0",
            "definition": "https://creativecommons.org/licenses/by-sa-nc/3.0/de/deed.en",
            "description": "The Creative Commons Attribution & Share-alike non-commercial license",
            "logo": "https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-sa.png"
        }
    },
    "datastreams": {
        "photo": {
            "@iot.id": "$DS_1_ID",
            "unitOfMeasurement": {
                "name": "n/a",
                "symbol": "",
                "definition": "https://www.merriam-webster.com/dictionary/picture"
            },
            "name": "photo datastream",
            "description": "this datastream is about pictures",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "ObservedProperty": {
                "name": "Picture",
                "definition": "https://www.merriam-webster.com/dictionary/picture",
                "description": "The image taken by the camera (the sensor)"
            },
            "Sensor": {
                "name": "Pi NoIR - Raspberry Pi Infrared Camera Module",
                "description": "Sony IMX 219 PQ CMOS image sensor in a fixed-focus module with IR blocking filter removed",
                "encodingType": "application/pdf",
                "metadata": "https://cdn-reichelt.de/documents/datenblatt/A300/RASP_CAN_2.pdf"
            },
            "License": {"@iot.id": "$CC_BY_ID"},
            "Party": {"@iot.id": "$AUTH_ID"},
            "Thing": {"@iot.id": "$THING_1_ID"},
            "Project": {"@iot.id": "$PROJECT_ID"}
        },
        "detection": {
            "@iot.id": "$DS_2_ID",
            "unitOfMeasurement": {
                "name": "GBIF Identity",
                "symbol": "n/a",
                "definition": "https://www.gbif.org/species"
            },
            "name": "GBIF Identifier for Species",
            "description": "The GBIF identifiers for species",
            "observationType": "GBIF Taxonomy",
            "ObservedProperty": {
                "name": "Taxon",
                "definition": "https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c",
                "description": "GBIF Backbone Taxonomy"
            },
            "Sensor": {
                "name": "DynAIkon AI for automatic species detection",
                "description": "The DynAIkon automatic species detection",
                "encodingType": "text/html",
                "metadata": "https://dynaikon.com/"
            },
            "License": {"@iot.id": "$CC_BY_NC_ID"},
            "Party": {"@iot.id": "$AUTH_ID"},
            "Thing": {"@iot.id": "$THING_1_ID"},
            "Project": {"@iot.id": "$PROJECT_ID"}
        }
    },
    "multi_datastreams": {
        "env": {
            "@iot.id": "$MDS_1_ID",
            "name": "Environmental Datastream from Camera Trap",
            "description": "Environment data for air temperature, humidity, pressure",
            "multiObservationDataTypes": [
                "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
                "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
                "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
                "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement"
            ],
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_ComplexObservation",
            "observedArea": {
                "type": "Point",
                "coordinates": [
                    $GPS_LON,
                    $GPS_LAT
                ]
            },
            "Party": {"@iot.id": "$AUTH_ID"},
            "properties": {
                "fieldOne": "Temperature",
                "fieldTwo": "Humidity",
                "fieldThree": "Preasure",
                "fieldFour": "Luminance"
            },
            "unitOfMeasurements": [
                {
                    "name": "Temperature",
                    "symbol": "C",
                    "definition": "http://www.qudt.org/qudt/owl/1.0.0/qudt/index.html#TemperatureUnit"
                },
                {
                    "name": "Humidity",
                    "symbol": "RH",
                    "definition": "https://byjus.com/physics/unit-of-humidity/"
                },
                {
                    "name": "Pressure",
                    "symbol": "mbar",
                    "definition": "https://en.wikipedia.org/wiki/Atmospheric_pressure"
                },
                {
                    "name": "Luminance",
                    "symbol": "cd/m2",
                    "definition": "https://en.wikipedia.org/wiki/Luminance"
                }
            ],
            "License": {"@iot.id": "$CC0_ID"},
            "Thing": {"@iot.id": "$THING_2_ID"},
            "Sensor": {
                "name": "Environment Sensor",
                "description": "This sensor produces temperature, humidity and pressure",
                "encodingType": "text/html",
                "metadata": "https://google.de",
                "properties": {"calibrated": "$DATE_TIME_NOW"}
            },
            "ObservedProperties": [
                {
                    "name": "DegC",
                    "definition": "https://en.wikipedia.org/wiki/Temperature",
                    "description": "Air Temperature in Celcius"
                },
                {
                    "name": "Relative Air Humidity",
                    "definition": "https://en.wikipedia.org/wiki/Humidity",
                    "description": "Air Humidity"
                },
                {
                    "description": "Atmospheric pressure",
                    "definition": "https://en.wikipedia.org/wiki/Atmospheric_pressure",
                    "name": "Atmospheric pressure"
                },
                {
                    "description": "Luminance",
                    "definition": "https://en.wikipedia.org/wiki/Luminance",
                    "name": "Luminance"
                }
            ],
            "Project": {"@iot.id": "$PROJECT_ID"}
        }
    }
}
EOF
)


echo "creating Party: $STA_URL/Parties('"$AUTH_ID"')"
echo $sta_setup_data | jq '.party'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Parties

echo "creating Project: $STA_URL/Projects('"$PROJECT_ID"')"
echo $sta_setup_data |jq '.project'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Projects

echo "creating Thing Raspberry: $STA_URL/Things('"$THING_1_ID"')"
echo $sta_setup_data |jq '.things.raspberry_pi'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Things

echo "creating Thing Env Board: $STA_URL/Things('"$THING_2_ID"')"
echo $sta_setup_data |jq '.things.env_board'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Things

echo "creating License CC0: $STA_URL/Licenses('"$CC0_ID"')"
echo $sta_setup_data |jq '.licenses.cc_zero'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo "creating License CC BY: $STA_URL/Licenses('"$CC_BY_ID"')"
echo $sta_setup_data |jq '.licenses.cc_by'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo "creating License CC BY-NC: $STA_URL/Licenses('"$CC_BY_NC_ID"')"
echo $sta_setup_data |jq '.licenses.cc_by_nc'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo "creating License CC BY-NC-SA: $STA_URL/Licenses('"$CC_BY_NC_SA_ID"')"
echo $sta_setup_data |jq '.licenses.cc_by_nc_sa'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo "creating License CC BY-SA: $STA_URL/Licenses('"$CC_BY_SA_ID"')"
echo $sta_setup_data |jq '.licenses.cc_by_sa'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo "creating Datastream Photo: $STA_URL/Datastreams('"$DS_1_ID"')"
echo $sta_setup_data |jq '.datastreams.photo'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo "creating Datastream Detection: $STA_URL/Datastreams('"$DS_2_ID"')"
echo $sta_setup_data |jq '.datastreams.detection'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo "creating MultiDatastream Environment: $STA_URL/MultiDatastreams('"$MDS_1_ID"')"
echo $sta_setup_data |jq '.multi_datastreams.env'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/MultiDatastreams


echo "writing sta_setup_ids.json"
umask 277
echo $sta_setup_ids > sta_setup_ids.json
