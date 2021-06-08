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


. ../sta.config

rm -f "sta_setup_ids.json"

AUTH_ID=$1
ACCESS_TOKEN=$2
STA_URL=$3
GPS_LON="$FOI_GPS_LON"
GPS_LAT="$FOI_GPS_LAT"
PROJECT_ID=$(uuidgen)
THING_RASPI_ID=$(uuidgen)
THING_ENV_ID=$(uuidgen)
FEATURE_ID=$(uuidgen)
CC0_ID=$(uuidgen)
CC_BY_ID=$(uuidgen)
CC_BY_NC_ID=$(uuidgen)
CC_BY_NC_SA_ID=$(uuidgen)
CC_BY_SA_ID=$(uuidgen)
DS_IMAGERY_ID=$(uuidgen)
DS_TAXON_ID=$(uuidgen)
DS_TEMPERATURE_ID=$(uuidgen)
DS_HUMIDITY_ID=$(uuidgen)
DS_PRESSURE_ID=$(uuidgen)
DS_BRIGHTNESS_ID=$(uuidgen)
DATE_TIME_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

sta_setup_ids=$(cat -s << EOF
{
    "auth_id": "$AUTH_ID",
    "project_id": "$PROJECT_ID",
    "thing_ids": [
        "$THING_RASPI_ID",
        "$THING_ENV_ID"
    ],
    "license_cc_zero_id": "$CC0_ID",
    "license_cc_by_id": "$CC_BY_ID",
    "license_cc_by_nc_id": "$CC_BY_NC_ID",
    "license_cc_by_nc_sa_id": "$CC_BY_NC_SA_ID",
    "license_cc_by_sa_id": "$CC_BY_SA_ID",
    "datastream_ids": {
        "imagery": "$DS_IMAGERY_ID",
        "taxon": "$DS_TAXON_ID",
        "temperature": "$DS_TEMPERATURE_ID",
        "humidity": "$DS_HUMIDITY_ID",
        "pressure": "$DS_PRESSURE_ID",
        "brightness": "$DS_BRIGHTNESS_ID"
    },
    "foi_id": "$FEATURE_ID"
}
EOF
)

sta_setup_data=$(cat -s << EOF
{
    "party": {
        "@iot.id": "$AUTH_ID",
        "name": "$PARTY_NAME",
        "description": "$PARTY_DESCRIPTION",
        "nickName": "$PARTY_NICKNAME",
        "role": "individual",
        "authId": "$AUTH_ID"
    },
    "project": {
        "@iot.id": "$PROJECT_ID",
        "name": "Species Detection by DynAIkon Camera Trap",
        "description": "The automatic detection of species by all participating camera traps",
        "url": "https://cos4cloud.demo.secure-dimensions.de/projects/cameratrap",
        "termsOfUse": "Please do not upload sensitive information!",
        "privacyPolicy": "This project stores the user's globally unique identifier that cannot be used to retrieve personal information.",
        "created": "$DATE_TIME_NOW",
        "classification": "public"
    },
    "things": {
        "raspberry_pi": {
            "@iot.id": "$THING_RASPI_ID",
            "name": "Raspberry Pi 4 B, 4x 1,5 GHz, 4 GB RAM, WLAN, BT",
            "description": "Raspberry Pi 4 Model B is the latest product in the popular Raspberry Pi range of computers",
            "properties": {
                "CPU": "1.4GHz",
                "RAM": "4GB"
            },
            "Locations": [
                {
                    "@iot.id": "camera_trap_location",
                    "name": "$TRAP_LOCATION_NAME",
                    "description": "$TRAP_LOCATION_DESCRIPTION",
                    "encodingType": "application/geo+json",
                    "location": {
                        "type": "Point",
                        "coordinates": [
                            $TRAP_GPS_LON,
                            $TRAP_GPS_LAT
                        ]
                    },
                    "properties": {
                        "city": "$TRAP_PROPERTIES_CITY",
                        "countryCode": "$TRAP_PROPERTIES_COUNTRY"
                    }
                }
            ]
        },
        "env_board": {
            "@iot.id": "$THING_ENV_ID",
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
                    "@iot.id": "camera_trap_location"
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
    "sensors": {
        "imagery": {
            "@iot.id": "sensor_imagery_id",
            "name": "Pi Camera - Raspberry Pi Camera Module",
            "description": "HD-Kamera Raspberry Pi v2.1",
            "encodingType": "application/pdf",
            "metadata": "https://cdn-reichelt.de/documents/datenblatt/A300/RASP_CAN_2.pdf"
        },
        "detection": {
            "@iot.id": "sensor_detection",
            "name": "DynAIkon AI for automatic species detection",
            "description": "The DynAIkon automatic species detection",
            "encodingType": "http://www.opengis.net/doc/IS/SensorML/2.0",
            "metadata": "https://dynaikon.com/"
        },
        "temperature": {
            "@iot.id": "sensor_temp",
            "name": "DS18B20 digital thermometer",
            "description": "Sensor provides 9-bit to 12-bit Celsius temperature measurements",
            "encodingType": "application/pdf",
            "metadata": "https://datasheets.maximintegrated.com/en/ds/DS18B20.pdf"
        },
        "humidityAndPressure": {
            "@iot.id": "sensor_atpr-humi",
            "name": "Bosch BME680 sensor",
            "description": "Raw physical pressure | Relative humidity",
            "encodingType": "application/pdf",
            "metadata": "https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme680-ds001.pdf"
        },
        "brightness": {
            "@iot.id": "sensor_brightness",
            "name": "SFH 3710 photo diode",
            "description": "Brightness; values range from 0% to 100%, 10 bit resolution, no calibration",
            "encodingType": "application/pdf",
            "metadata": "https://www.digchip.com/datasheets/download_datasheet.php?id=3789002&part-number=SFH+3710-3%2F4-Z"
        }
    },
    "datastreams": {
        "imagery": {
            "@iot.id": "$DS_IMAGERY_ID",
            "name": "imagery datastream",
            "description": "this datastream is about imagery",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_TextObservation",
            "ObservedProperty": {
                "name": "Picture",
                "definition": "https://www.merriam-webster.com/dictionary/picture",
                "description": "The image taken by the camera (the sensor)"
            },
            "unitOfMeasurement": {
                "name": "n/a",
                "symbol": "",
                "definition": "https://www.merriam-webster.com/dictionary/picture"
            },
            "Sensor": {
                "@iot.id": "sensor_imagery_id"
            },
            "License": {
                "@iot.id": "$CC_BY_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_RASPI_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        },
        "taxon": {
            "@iot.id": "$DS_TAXON_ID",
            "name": "GBIF Identifier for Species",
            "description": "The GBIF identifiers for species",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_TextObservation",
            "ObservedProperty": {
                "name": "Taxon",
                "definition": "https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c",
                "description": "GBIF Backbone Taxonomy"
            },
            "unitOfMeasurement": {
                "name": "GBIF Identity",
                "symbol": "n/a",
                "definition": "https://www.gbif.org/species"
            },
            "Sensor": {
                "@iot.id": "sensor_detection"
            },
            "License": {
                "@iot.id": "$CC_BY_NC_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_RASPI_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        },
        "temperature": {
            "@iot.id": "$DS_TEMPERATURE_ID",
            "unitOfMeasurement": {
                "name": "Temperature",
                "symbol": "C",
                "definition": "http://www.qudt.org/qudt/owl/1.0.0/qudt/index.html#TemperatureUnit"
            },
            "name": "Temperature",
            "description": "Temperature at the rabbit box",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "ObservedProperty": {
                "name": "DegC",
                "definition": "https://en.wikipedia.org/wiki/Temperature",
                "description": "Air Temperature in Celcius"
            },
            "Sensor": {
                "@iot.id": "sensor_detection"
            },
            "License": {
                "@iot.id": "$CC_BY_NC_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_ENV_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        },
        "rh": {
            "@iot.id": "$DS_HUMIDITY_ID",
            "name": "Relative Humidity",
            "description": " The ratio of how much water vapour is in the air and how much water vapour the air could potentially contain",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "ObservedProperty": {
                "name": "relative_humidity",
                "definition": "https://en.wikipedia.org/wiki/Humidity#Relative_humidity",
                "description": "The ratio of how much water vapour is in the air and how much water vapour the air could potentially contain at a given temperature."
            },
            "unitOfMeasurement": {
                "name": "percent",
                "symbol": "%",
                "definition": "https://en.wikipedia.org/wiki/Percentage"
            },
            "Sensor": {
                "@iot.id": "sensor_atpr-humi"
            },
            "License": {
                "@iot.id": "$CC_BY_NC_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_ENV_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        },
        "pressure": {
            "@iot.id": "$DS_PRESSURE_ID",
            "name": "Pressure",
            "description": "Atmospheric air pressure",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "ObservedProperty": {
                "name": "Pressure",
                "definition": "https://en.wikipedia.org/wiki/Atmospheric_pressure",
                "description": "(Barometric) pressure within the atmosphere of Earth."
            },
            "unitOfMeasurement": {
                "name": "milli bar",
                "symbol": "mbar",
                "definition": "http://www.qudt.org/qudt/owl/1.0.0/qudt/index.html#LuminanceUnit"
            },
            "Sensor": {
                "@iot.id": "sensor_atpr-humi"
            },
            "License": {
                "@iot.id": "$CC_BY_NC_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_ENV_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        },
        "brightness": {
            "@iot.id": "$DS_BRIGHTNESS_ID",
            "name": "Brightness",
            "description": "Photometric measure of the luminous intensity per unit area of light travelling in a given direction",
            "observationType": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "ObservedProperty": {
                "name": "Brigthness",
                "description": "Attribute of visual perception in which a source appears to be radiating or reflecting light.",
                "definition": "https://en.wikipedia.org/wiki/Brightness"
            },
            "unitOfMeasurement": {
                "name": "percent",
                "symbol": "%",
                "definition": "https://en.wikipedia.org/wiki/Percentage"
            },
            "Sensor": {
                "@iot.id": "sensor_brightness"
            },
            "License": {
                "@iot.id": "$CC_BY_NC_ID"
            },
            "Party": {
                "@iot.id": "$AUTH_ID"
            },
            "Thing": {
                "@iot.id": "$THING_ENV_ID"
            },
            "Project": {
                "@iot.id": "$PROJECT_ID"
            }
        }
    },
    "feature": {
        "@iot.id": "$FEATURE_ID",
        "name": "$FOI_NAME",
        "description": "$FOI_DESCRIPTION",
        "encodingType": "application/geo+json",
        "feature": {
            "type": "Point",
            "coordinates": [
                $FOI_GPS_LON,
                $FOI_GPS_LAT
            ]
        }
    }
}
EOF
)


echo -e "\n\n"
echo "creating Party: $STA_URL/Parties("$AUTH_ID")"
echo $sta_setup_data | jq '.party'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Parties

echo -e "\n\n"
echo "creating Project: $STA_URL/Projects("$PROJECT_ID")"
echo $sta_setup_data |jq '.project'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Projects

echo -e "\n\n"
echo "creating Feature: $STA_URL/FeaturesOfInterest("$PROJECT_ID")"
echo $sta_setup_data |jq '.feature'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/FeaturesOfInterest


## Create Things

echo -e "\n\n"
echo "creating Thing Raspberry: $STA_URL/Things("$THING_RASPI_ID")"
echo $sta_setup_data |jq '.things.raspberry_pi'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Things

echo -e "\n\n"
echo "creating Thing Env Board: $STA_URL/Things("$THING_ENV_ID")"
echo $sta_setup_data |jq '.things.env_board'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Things


## Create Licenses

echo -e "\n\n"
echo "creating License CC0: $STA_URL/Licenses("$CC0_ID")"
echo $sta_setup_data |jq '.licenses.cc_zero'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo -e "\n\n"
echo "creating License CC BY: $STA_URL/Licenses("$CC_BY_ID")"
echo $sta_setup_data |jq '.licenses.cc_by'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo -e "\n\n"
echo "creating License CC BY-NC: $STA_URL/Licenses("$CC_BY_NC_ID")"
echo $sta_setup_data |jq '.licenses.cc_by_nc'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo -e "\n\n"
echo "creating License CC BY-NC-SA: $STA_URL/Licenses("$CC_BY_NC_SA_ID")"
echo $sta_setup_data |jq '.licenses.cc_by_nc_sa'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses

echo -e "\n\n"
echo "creating License CC BY-SA: $STA_URL/Licenses("$CC_BY_SA_ID")"
echo $sta_setup_data |jq '.licenses.cc_by_sa'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Licenses


## Create Sensors

echo -e "\n\n"
echo "creating Sensor Camera: $STA_URL/Sensors("$DS_IMAGERY_ID")"
echo $sta_setup_data |jq '.sensors.imagery'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Sensors

echo -e "\n\n"
echo "creating Sensor Detection: $STA_URL/Sensors(sensor_detection)"
echo $sta_setup_data |jq '.sensors.detection'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Sensors

echo -e "\n\n"
echo "creating Sensor Temperature: $STA_URL/Sensors(sensor_temp)"
echo $sta_setup_data |jq '.sensors.temperature'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Sensors

echo -e "\n\n"
echo "creating Sensor humidity | pressure: $STA_URL/Sensors(sensor_atpr-humi)"
echo $sta_setup_data |jq '.sensors.humidityAndPressure'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Sensors

echo -e "\n\n"
echo "creating Sensor brightness: $STA_URL/Sensors(sensor_brightness)"
echo $sta_setup_data |jq '.sensors.brightness'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Sensors


## Create Datastreams

echo "\n\n"
echo "creating Datastream Photo: $STA_URL/Datastreams("$DS_IMAGERY_ID")"
echo $sta_setup_data |jq '.datastreams.imagery'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo -e "\n\n"
echo "creating Datastream Taxon: $STA_URL/Datastreams("$DS_TAXON_ID")"
echo $sta_setup_data |jq '.datastreams.taxon'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo -e "\n\n"
echo "creating Datastream Temperature: $STA_URL/Datastreams("$DS_TEMPERATURE_ID")"
echo $sta_setup_data |jq '.datastreams.temperature'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo -e "\n\n"
echo "creating Datastream Rel. Humidity: $STA_URL/Datastreams("$DS_TAXON_ID")"
echo $sta_setup_data |jq '.datastreams.rh'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo -e "\n\n"
echo "creating Datastream Atm. Pressure: $STA_URL/Datastreams("$DS_PRESSURE_ID")"
echo $sta_setup_data |jq '.datastreams.pressure'|curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams

echo -e "\n\n"
echo "creating Datastream Brightness: $STA_URL/Datastreams("$DS_BRIGHTNESS_ID")"
brightness=$(echo $sta_setup_data |jq '.datastreams.brightness')
echo $brightness
echo $brightness |curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -X POST --data-binary @- $STA_URL/Datastreams


echo -e "\n\n"
echo "writing sta_setup_ids.json"
umask 277
echo $sta_setup_ids > sta_setup_ids.json
