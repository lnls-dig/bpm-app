#!/usr/bin/env bash

set -eu

ERICS="$(realpath "$1")"

if [ ! -e "${ERICS}/utcaApp" ]; then
    echo "Make sure '${ERICS}' is an erics directory" >&2
    exit 1
fi

. crate_list.sh

for crate in "${CRATES[@]}"; do
    echo $crate
    crate=root@${crate}

    rsync -r "${ERICS}" ${crate}:/opt/
    ssh ${crate} "
        mkdir -p /var/opt/erics &&
        chown bpm-epics-ioc:bpm-epics-ioc /var/opt/erics &&
        cd /opt/erics &&
        cp service/95-erics.rules /etc/udev/rules.d &&
        cp service/erics-{tim,fofb}@.service /etc/systemd/system &&
        udevadm control -R &&
        echo 'epicsEnvSet(TOP, /opt/erics)' >> iocBoot/iocutca/envPaths &&
        echo 'epicsEnvSet(AUTOSAVE_PATH, /var/opt/erics)' >> iocBoot/iocutca/envPaths &&
        systemctl daemon-reload &&
        systemctl --no-block restart erics-tim@1 erics-fofb@2-1"
done
