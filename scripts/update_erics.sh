#!/usr/bin/env bash

set -eu

ERICS="$(realpath "$1")"

USER=iocs

if [ ! -e "${ERICS}/utcaApp" ]; then
    echo "Make sure '${ERICS}' is an erics directory" >&2
    exit 1
fi

. crate_list.sh

for crate in "${CRATES[@]}"; do
    echo $crate
    crate=root@${crate}

    rsync -r --exclude ".git" "${ERICS}" ${crate}:/opt/
    ssh ${crate} "
        mkdir -p /var/opt/erics && (useradd $USER || true) &&
        chown -R ${USER}:${USER} /var/opt/erics &&
        cd /opt/erics &&
        cp service/95-erics.rules /etc/udev/rules.d &&
        cp service/erics-{tim,fofb}@.service /etc/systemd/system &&
        udevadm control -R &&
        echo 'epicsEnvSet(TOP, /opt/erics)' >> iocBoot/iocutca/envPaths &&
        echo 'epicsEnvSet(AUTOSAVE_PATH, /var/opt/erics)' >> iocBoot/iocutca/envPaths &&
        systemctl daemon-reload &&
        systemctl --no-block restart erics-tim@1 erics-fofb@2-1"
done
