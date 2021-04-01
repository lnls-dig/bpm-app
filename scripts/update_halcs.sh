#!/usr/bin/env bash

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
        cd /root/postinstall/apps/bpm-app/halcs && \
        git fetch --all && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        git checkout master && \
        git reset --hard origin/master && \
        cp /usr/local/etc/halcs/halcs.cfg /home/lnls-bpm/halcs.cfg.temp && \
        systemctl stop halcs@{1,2,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        cd /root/postinstall/apps/bpm-app/halcs && \
        ./gradle_uninstall.sh && \
        ./gradle_compile.sh -a halcsd -b afcv3_1 -e yes && \
        mv /home/lnls-bpm/halcs.cfg.temp /usr/local/etc/halcs/halcs.cfg && \
        systemctl daemon-reload && \
        cd /root/postinstall/apps/bpm-app/halcs-generic-udev && \
        make install &&  \
        (chmod 777 /tmp/malamute || :) && \
        systemctl start halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        systemctl start tim-rx-ioc@{1,2}" &

done
