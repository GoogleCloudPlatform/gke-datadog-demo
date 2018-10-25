#! /usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Common commands for all scripts                      -"
# "-                                                       -"
# "---------------------------------------------------------"

# gcloud and kubectl are required for this demo
command -v gcloud >/dev/null 2>&1 || { \
 echo >&2 "I require gcloud but it's not installed.  Aborting."; exit 1; }

command -v kubectl >/dev/null 2>&1 || { \
 echo >&2 "I require kubectl but it's not installed.  Aborting."; exit 1; }

# Get the default zone and use it or die
ZONE=$(gcloud config get-value compute/zone)
if [ -z "${ZONE}" ]; then
    echo "gcloud cli must be configured with a default zone." 1>&2
    echo "run 'gcloud config set compute/zone ZONE'." 1>&2
    echo "replace 'ZONE' with the zone name like us-west1-a." 1>&2
    exit 1;
fi

#Get the default region and use it or die
REGION=$(gcloud config get-value compute/region)
if [ -z "${REGION}" ]; then
    echo "gcloud cli must be configured with a default region." 1>&2
    echo "run 'gcloud config set compute/region REGION'." 1>&2
    echo "replace 'REGION' with the region name like us-west1." 1>&2
    exit 1;
fi

# Get a comma separated list of zones from the default region
ZONESINREGION=""
for FILTEREDZONE in $(gcloud compute zones list --filter="region:$REGION" \
  --format="value(name)" --limit 2)
do
  ZONESINREGION+="$FILTEREDZONE,"
done
#Remove the last comma from the starting
ZONESINREGION=${ZONESINREGION%?}

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Common functions for all scripts                     -"
# "-                                                       -"
# "---------------------------------------------------------"

# Waiting for website to comes up
function wait_for_server () {
attempt_counter=0
max_attempts=5
site=$1
until curl --output /dev/null --silent --head --fail "$site"; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$((attempt_counter+1))
    sleep 5
done
}

function wait_for_service_okay() {
  # Define retry constants
  local -r MAX_COUNT=60
  local -r RETRY_COUNT=0
  local -r SLEEP=2
  local -r url=$1
  # Curl for the service with retries
  STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$url")
  until [[ $STATUS_CODE -eq 200 ]]; do
      if [[ "${RETRY_COUNT}" -gt "${MAX_COUNT}" ]]; then
      # failed with retry, lets check whatz wrong and bail
      echo "Retry count exceeded. Exiting..."
      # Timed out?
      if [ -z "$STATUS_CODE" ]
      then
        echo "ERROR - Timed out waiting for service"
        exit 1
      fi
      # HTTP status not okay?
      if [ "$STATUS_CODE" != "200" ]
      then
        echo "ERROR - Service is returning error"
        exit 1
      fi
      fi
      NUM_SECONDS="$(( RETRY_COUNT * SLEEP ))"
      echo "Waiting for service availability..."
      echo "service / did not return an HTTP 200 response code after ${NUM_SECONDS} seconds"
      sleep "${SLEEP}"
      RETRY_COUNT="$(( RETRY_COUNT + 1 ))"
      STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$EXT_IP:$EXT_PORT/")
  done
}