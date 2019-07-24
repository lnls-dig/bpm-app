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
        cd /opt/epics && \
        rm base && \
        ln -s base-3.14.12.6 base && \
        systemctl stop halcs@{1,2}.target && \
        systemctl stop tim-rx-ioc@{1,2} && \
        systemctl stop halcs@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        systemctl stop halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        cd /opt/epics/synApps-lnls-R1-2-1/support && \
        make clean && make && \
        systemctl stop halcs@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        cp /etc/sysconfig/bpm-epics-ioc /home/lnls-bpm/bpm-epics-ioc.temp && \
        cd /root/postinstall/apps/bpm-app/bpm-epics-ioc && \
        make clean && make && make install && \
        mv /home/lnls-bpm/bpm-epics-ioc.temp /etc/sysconfig/bpm-epics-ioc && \
        systemctl daemon-reload && \
        systemctl start halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        systemctl stop halcs@{1,2}.target && \
        cp /etc/sysconfig/tim-rx-epics-ioc /home/lnls-bpm/tim-rx-epics-ioc.temp && \
        cd /root/postinstall/apps/tim-rx-app/tim-rx-epics-ioc && \
        make clean && make && make install && \
        mv /home/lnls-bpm/tim-rx-epics-ioc.temp /etc/sysconfig/tim-rx-epics-ioc && \
        systemctl daemon-reload && \
        systemctl start tim-rx-ioc@{1,2}" | tee update_ioc_log_${crate}.log 2>&1 &

done
