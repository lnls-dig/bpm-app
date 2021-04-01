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
        yum -y install epel-release centos-release-scl centos-release-scl-rh && \
        yum -y install cmake3 dkms && \
        cd /root/postinstall/apps/bpm-app/halcs && \
        git fetch --all && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        (cp /usr/local/etc/halcs/halcs.cfg /home/lnls-bpm/halcs.cfg.temp || \
        cp /etc/halcs/halcs.cfg /home/lnls-bpm/halcs.cfg.temp) && \
        systemctl stop halcs@{1,2,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        cd /root/postinstall/apps/bpm-app/halcs && \
        ./gradle_uninstall.sh; \
        git reset --hard origin/master && \
        git submodule update && \
        rm -rf build && \
        mkdir -p build && \
        cd build && \
        cmake3 ../ && \
        cpack3 -G \"RPM\" && \
        rpm -e halcsd; \
        rpm -e halcsd-debuginfo; \
        rpm -i halcsd-debuginfo*; \
        rpm -i halcsd-afcv3_1_*_x86_64.rpm && \
        ldconfig && \
        mv /home/lnls-bpm/halcs.cfg.temp /etc/halcs/halcs.cfg && \
        systemctl daemon-reload && \
        systemctl start halcs-ioc@{5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        systemctl start tim-rx-ioc@1" &

done
