#!/usr/bin/env bash

if [ ! $# -eq 1 ]
then
    echo "Wrong usage! $0 <COMMIT_ID>"
    exit
fi

COMMIT_ID=$1

. ./crate_list.sh

for crate in "${CRATES[@]}"; do
    ssh root@${crate} "
        set -x && \
        mkdir -p /opt/epics/ioc && \
        cd /opt/epics/ioc && \
        (git clone https://github.com/lnls-dig/bpm-epics-ioc || (cd bpm-epics-ioc && git fetch --all)) && \
        cd /opt/epics/ioc/bpm-epics-ioc && \
        systemctl stop halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        cp /etc/sysconfig/bpm-epics-ioc /home/lnls-bpm/bpm-epics-ioc.temp && \
        make uninstall && \
        git reset --hard ${COMMIT_ID} && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        make clean && \
        make && \
        make install && \
        (chmod 777 /tmp/malamute || :) && \
        mv /home/lnls-bpm/bpm-epics-ioc.temp /etc/sysconfig/bpm-epics-ioc && \
        chown -R bpm-epics-ioc:bpm-epics-ioc /opt/epics/ioc/bpm-epics-ioc && \
        systemctl daemon-reload && \
        systemctl start halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target" &

done
