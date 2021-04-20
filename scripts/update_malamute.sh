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
        cd /root/postinstall/apps/bpm-app/malamute && \
        systemctl stop malamute && \
        git fetch --all && \
        git clean -fd && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
        git checkout master && \
        git reset --hard origin/master && \
        systemctl stop halcs@{1,2,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        ./autogen.sh && \
        ./configure --with-systemd-units --sysconfdir=/usr/etc --prefix=/usr &&
        make && \
        sudo make install && \
        sudo ldconfig && \
        MALAMUTE_VERBOSE=0 && \
        MALAMUTE_PLAIN_AUTH= && \
        MALAMUTE_AUTH_MECHANISM=null && \
        MALAMUTE_ENDPOINT='ipc:///tmp/malamute' && \
        MALAMUTE_CFG_FILE=/usr/etc/malamute/malamute.cfg && \
        sudo sed -i \
          -e \"s|verbose\( *\)=.*|verbose\1= 0|g\" \
          -e \"s|plain\( *\)=.*|plain\1= |g\" \
          -e \"s|mechanism\( *\)=.*|mechanism\1= null|g\" \
          -e \"s|tcp://\*:9999|ipc:///tmp/malamute|g\" \
          /usr/etc/malamute/malamute.cfg && \
        systemctl daemon-reload && \
        (chmod 777 /tmp/malamute || :) && \
        systemctl start malamute && \
        systemctl start halcs-ioc@{7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}.target && \
        systemctl start tim-rx-ioc@{1,2}" &

done
