#!/usr/bin/env bash

if [ ! $# -eq 1 ]
then
    echo "Wrong usage! $0 <COMMIT_ID>"
    exit
fi

COMMIT_ID=$1

CRATES=()
CRATES+=("IA-01RaBPM-CO-IOCSrv")
CRATES+=("IA-02RaBPM-CO-IOCSrv")
CRATES+=("IA-03RaBPM-CO-IOCSrv")
CRATES+=("IA-04RaBPM-CO-IOCSrv")
CRATES+=("IA-05RaBPM-CO-IOCSrv")
CRATES+=("IA-06RaBPM-CO-IOCSrv")
CRATES+=("IA-07RaBPM-CO-IOCSrv")
CRATES+=("IA-08RaBPM-CO-IOCSrv")
CRATES+=("IA-09RaBPM-CO-IOCSrv")
CRATES+=("IA-10RaBPM-CO-IOCSrv")
CRATES+=("IA-11RaBPM-CO-IOCSrv")
CRATES+=("IA-12RaBPM-CO-IOCSrv")
CRATES+=("IA-13RaBPM-CO-IOCSrv")
CRATES+=("IA-14RaBPM-CO-IOCSrv")
CRATES+=("IA-15RaBPM-CO-IOCSrv")
CRATES+=("IA-16RaBPM-CO-IOCSrv")
CRATES+=("IA-17RaBPM-CO-IOCSrv")
CRATES+=("IA-18RaBPM-CO-IOCSrv")
CRATES+=("IA-19RaBPM-CO-IOCSrv")
CRATES+=("IA-20RaBPM-CO-IOCSrv")
CRATES+=("IA-20RaBPMTL-CO-IOCSrv")

for crate in "${CRATES[@]}"; do

    SSHPASS=root sshpass -e ssh -o StrictHostKeyChecking=no root@${crate} bash -c "\
        set -x && \
        mkdir -p /opt/epics/ioc && \
        cd /opt/epics/ioc && \
        (git clone https://github.com/lnls-dig/bpm-epics-ioc || (cd bpm-epics-ioc && git fetch --all)) && \
        cd /opt/epics/ioc/bpm-epics-ioc && \
        git reset --hard ${COMMIT_ID} && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        cp /etc/sysconfig/bpm-epics-ioc /home/lnls-bpm/bpm-epics-ioc.temp && \
        systemctl stop halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        make clean && \
        make && \
        make install && \
        (chmod 777 /tmp/malamute || :) && \
        mv /home/lnls-bpm/bpm-epics-ioc.temp /etc/sysconfig/bpm-epics-ioc && \
        chown -R bpm-epics-ioc:bpm-epics-ioc /opt/epics/ioc/bpm-epics-ioc && \
        systemctl daemon-reload && \
        systemctl start halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target" &

done
