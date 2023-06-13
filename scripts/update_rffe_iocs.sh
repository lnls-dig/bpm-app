#!/usr/bin/env bash

set -eu

if [ ! $# -eq 1 ]
then
    echo "Wrong usage! $0 <BRANCH>"
    exit
fi

BRANCH=$1

. crate_list.sh

# TODO: restart containers with outdated base image

for crate in "${CRATES[@]}"; do
    ssh root@${crate} "
        echo $crate
        mkdir -p /opt/rffe-epics-ioc &&
        cd /opt/rffe-epics-ioc && rm -f docker-compose.yml &&
        wget https://raw.githubusercontent.com/lnls-dig/rffe-epics-ioc/${BRANCH}/deploy/docker-compose.yml &&
        mkdir -p /var/opt/rffe-epics-ioc &&
        docker-compose pull" &
done
