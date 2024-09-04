#!/usr/bin/env bash

set -eu

if [ ! $# -eq 1 ]; then
    echo "Wrong usage! $0 <TARBALL>"
    exit 1
fi

TARBALL=$1

if [ ! -f "$TARBALL" ]; then
    echo "Missing tarball"
    exit 1
fi

. crate_list.sh

for crate in "${CRATES[@]}"; do
    (ssh root@${crate} tar xzf - -C /opt < "$TARBALL"
    ssh root@${crate} "
        mkdir -p /var/opt/rffe-epics-ioc &&
        chown -R iocs /var/opt/rffe-epics-ioc &&
        cd /opt/rffe-epics-ioc &&
        cp service/rffe-ioc@.service /etc/systemd/system &&
        systemctl daemon-reload &&
        systemctl restart rffe-ioc@{11..23}") &> /tmp/update_rffe_ioc_$crate.log 2>&1 &
done

wait

for crate in "${CRATES[@]}"; do
    echo $crate
    cat /tmp/update_rffe_ioc_$crate.log
done
