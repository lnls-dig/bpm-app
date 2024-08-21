#!/usr/bin/env bash

set -eu

AFC_IOC="$(realpath "$1")"
DECODE_REG="$(realpath "$2")"

USER=iocs

if [ ! -e "${AFC_IOC}/utcaApp" -a "$(basename "$AFC_IOC")" = afc-epics-ioc ]; then
    echo "Make sure '${AFC_IOC}' is an afc-epics-ioc directory" >&2
    exit 1
fi

if [ ! -x "${DECODE_REG}" -a "$(basename "$DECODE_REG")" = decode-reg ]; then
    echo "Make sure '${DECODE_REG}' is a decode-reg executable" >&2
    exit 1
fi

. crate_list.sh

for crate in "${CRATES[@]}"; do
    echo $crate
    login=root@${crate}

    (rsync -rz --exclude ".git" "${AFC_IOC}" ${login}:/opt/
    rsync -z "${DECODE_REG}" ${login}:/usr/local/bin
    ssh ${login} "
        mkdir -p /var/opt/afc-epics-ioc &&
        chown -R ${USER} /var/opt/afc-epics-ioc &&
        cd /opt/afc-epics-ioc &&
        cp service/95-afc.rules /etc/udev/rules.d &&
        cp service/afc-ioc@.service /etc/systemd/system &&
        udevadm control -R &&
        echo 'epicsEnvSet(TOP, /opt/afc-epics-ioc)' >> iocBoot/iocutca/envPaths &&
        echo 'epicsEnvSet(AUTOSAVE_PATH, /var/opt/afc-epics-ioc)' >> iocBoot/iocutca/envPaths &&
        systemctl daemon-reload &&
        systemctl --no-block restart afc-ioc@{1,2-1,4,5,6,7,8,9,10,11,12}") &> /tmp/update_afc_ioc_$crate.log &
done

wait

for crate in "${CRATES[@]}"; do
    echo $crate
    cat /tmp/update_afc_ioc_$crate.log
done
