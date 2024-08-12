#!/usr/bin/env bash

set -eu

if [ ! $# -eq 1 ]
then
    echo "Wrong usage! $0 <BRANCH>"
    exit
fi

BRANCH=$1
USER=iocs

. crate_list.sh

for crate in "${CRATES[@]}"; do
    ssh root@${crate} "
        echo $crate
        mkdir -p /opt/rffe-epics-ioc &&
        cd /opt/rffe-epics-ioc && rm -f docker-compose.yml &&
        wget https://raw.githubusercontent.com/lnls-dig/rffe-epics-ioc/${BRANCH}/deploy/docker-compose.yml &&
        mkdir -p /var/opt/rffe-epics-ioc &&
        chown -R $USER /var/opt/rffe-epics-ioc &&
        sudo -u $USER podman-compose pull rffe-ioc-1 &&
        services=\$(sudo -u $USER podman ps --filter name=rffe-epics-ioc_rffe-ioc --format '{{.Names}}' | sed -e s/rffe-epics-ioc_// -e s/_1//) &&
        sudo -u $USER podman-compose down -t 0 &&
        sudo -u $USER \
            CRATE_NUMBER=\$(/opt/afc-epics-ioc/iocBoot/iocutca/getCrate.sh) \
            podman-compose up -d \$services
    " &> /tmp/update_rffe_iocs_${crate}.log &
done

wait

for crate in "${CRATES[@]}"; do
    echo $crate
    cat /tmp/update_rffe_iocs_${crate}.log
done
