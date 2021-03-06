#!/bin/bash -u

# Copyright 2018 ConsenSys AG.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

NO_LOCK_REQUIRED=false

. ./.env
. ./.common.sh

removeDockerImage(){
  if [[ ! -z `docker ps -a | grep $1` ]]; then
    docker image rm $1
  fi
}

echo "${bold}*************************************"
echo "Quorum Dev Quickstart "
echo "*************************************${normal}"
echo "Stop and remove network..."
docker-compose -f docker-compose.yml -f docker-compose-override.yml down -v
docker-compose -f docker-compose.yml -f docker-compose-override.yml rm -sfv

if [ -f "docker-compose-deps.yml" ]; then
    echo "Stopping dependencies..."
    docker-compose -f docker-compose-deps.yml down -v
    docker-compose rm -sfv
fi
# pet shop dapp
if [[ ! -z `docker ps -a | grep quorum-dev-quickstart_pet_shop` ]]; then
  docker stop quorum-dev-quickstart_pet_shop
  docker rm quorum-dev-quickstart_pet_shop
  removeDockerImage quorum-dev-quickstart_pet_shop
fi

rm_image=${1:-nrmi}

if [ $rm_image == "-rmi" ]; then
  echo "Removing images"
  docker image rm quorum-dev-quickstart/block-explorer-light:develop
  docker image rm consensys/quorum-ethsigner:${QUORUM_ETHSIGNER_VERSION}
  if grep -q 'orion:' docker-compose.yml 2> /dev/null ; then
    docker image rm consensys/quorum-orion:${QUORUM_ORION_VERSION}
  fi
  if grep -q 'besu:' docker-compose.yml 2> /dev/null ; then
    docker image rm hyperledger/besu:${BESU_VERSION}
  fi
  if grep -q 'tessera:' docker-compose.yml 2> /dev/null ; then
    docker image rm quorumengineering/tessera:${QUORUM_TESSERA_VERSION}
  fi
  if grep -q 'quorum:' docker-compose.yml 2> /dev/null ; then
    docker image rm quorumengineering/quorum:${QUORUM_VERSION}
  fi
  if grep -q 'cakeshop:' docker-compose.yml 2> /dev/null ; then
    docker image rm quorumengineering/cakeshop:${QUORUM_CAKESHOP_VERSION}
  fi
  if grep -q 'kibana:' docker-compose.yml 2> /dev/null ; then
    docker image rm quorum-test-network_elasticsearch
    docker image rm quorum-test-network_logstash
    docker image rm quorum-test-network_filebeat
    docker image rm quorum-test-network_metricbeat
  fi
else
  echo "Skipping image removal"
fi

rm ${LOCK_FILE}
echo "Lock file ${LOCK_FILE} removed"
