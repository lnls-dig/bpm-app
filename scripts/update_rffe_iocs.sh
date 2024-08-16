#!/usr/bin/env bash

set -eu

if [ ! $# -eq 1 ]
then
    echo "Wrong usage! $0 <BRANCH>"
    exit
fi

BRANCH=$1
REPOSITORY=https://raw.githubusercontent.com/lnls-dig/rffe-epics-ioc/${BRANCH}
USER=iocs

. crate_list.sh

for crate in "${CRATES[@]}"; do
    ssh root@${crate} "
        echo $crate
        mkdir -p /opt/rffe-epics-ioc &&
        cd /opt/rffe-epics-ioc && rm -f docker-compose.yml &&
        wget $REPOSITORY/deploy/docker-compose.yml &&
        mkdir -p /var/opt/rffe-epics-ioc &&
        chown -R $USER /var/opt/rffe-epics-ioc &&
        sudo -u $USER podman-compose pull rffe-ioc-1 &&
        sudo -u $USER podman-compose down -t 0 &&
        wget $REPOSITORY/deploy/rffe-ioc@.service -O /etc/systemd/system/rffe-ioc@.service &&
        systemctl daemon-reload &&
        systemctl restart --no-block rffe-ioc@{11..23}
    " &> /tmp/update_rffe_iocs_${crate}.log &
done

wait

for crate in "${CRATES[@]}"; do
    echo $crate
    cat /tmp/update_rffe_iocs_${crate}.log
done
