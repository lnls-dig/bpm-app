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
#CRATES+=("IA-20RaBPMTL-CO-IOCSrv")

for crate in "${CRATES[@]}"; do

    SSHPASS=root sshpass -e ssh -o StrictHostKeyChecking=no root@${crate} bash -c "\
        set -x && \
        mkdir -p /opt/epics/ioc && \
        cd /opt/epics/ioc && \
        (git clone https://github.com/lnls-dig/fofb-epics-ioc || (cd fofb-epics-ioc && git fetch --all)) && \
        cd /opt/epics/ioc/fofb-epics-ioc && \
        git reset --hard ${COMMIT_ID} && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        (systemctl stop fofb-ioc@5 || :) && \
        cp /etc/sysconfig/fofb-epics-ioc /home/lnls-bpm/fofb-epics-ioc.temp && \
        make clean && \
        make && \
        make install && \
        (chmod 777 /tmp/malamute || :) && \
        mv /home/lnls-bpm/fofb-epics-ioc.temp /etc/sysconfig/fofb-epics-ioc && \
        chown -R fofb-epics-ioc:fofb-epics-ioc /opt/epics/ioc/fofb-epics-ioc && \
        systemctl daemon-reload && \
        (systemctl start fofb-ioc@5 || :)" &

done
