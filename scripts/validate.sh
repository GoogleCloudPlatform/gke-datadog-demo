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
# "-  Validation script checks if demo application         -"
# "-  deployed successfully.                               -"
# "-                                                       -"
# "---------------------------------------------------------"

# Do not set exit on error, since the rollout status command may fail
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# shellcheck source=scripts/common.sh
source "$ROOT/scripts/common.sh"

APP_NAME="nginx"

# Loop for up to 60 seconds waiting for service's IP address
EXT_IP=""
for _ in {1..30}; do
  EXT_IP=$(kubectl get svc "$APP_NAME" -n default \
    -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ ! -z "$EXT_IP" ] && break
  sleep 2
done
if [ -z "$EXT_IP" ]
then
  echo "ERROR - Timed out waiting for IP"
  exit 1
fi

echo "Step 1 of the validation passed. nginx deployed successfully."

# Get service's port
EXT_PORT=$(kubectl get service "$APP_NAME" -n default \
  -o=jsonpath='{.spec.ports[0].port}')

echo "App is available at: http://$EXT_IP:$EXT_PORT"

# Test service availability
[ "$(curl -s -o /dev/null -w '%{http_code}' "$EXT_IP:$EXT_PORT"/)" \
  -eq 200 ] || exit 1

echo "Step 2 of the validation passed. App handles requests."
