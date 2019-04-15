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
	    cd /root/postinstall/apps/tim-rx-app/tim-rx-epics-ioc && \
	    git fetch --all && \
        git checkout -b stable-\$(date +%Y%m%d-%H%M%S) && \
	    git checkout master && \
	    git reset --hard origin/master && \
	    cp /etc/sysconfig/tim-rx-epics-ioc /home/lnls-bpm/tim-rx-epics-ioc.temp && \
	    systemctl stop tim-rx-ioc@{1,2} && \
	    make clean && \
	    make && \
	    make install && \
	    mv /home/lnls-bpm/tim-rx-epics-ioc.temp /etc/sysconfig/tim-rx-epics-ioc && \
	    systemctl daemon-reload && \
	    systemctl start tim-rx-ioc@{1,2}"

done
