#!/usr/bin/env bash

set -eu

USER=iocs

if [ ! $# -eq 1 ]; then
    echo "Wrong usage! $0 <TARBALL>"
    exit 1
fi

TARBALL=$1

if [ ! -f "$TARBALL" ]; then
    echo "Missing tarball"
    exit 1
fi

. crate_list.sh

for crate in "${CRATES[@]}"; do
    (ssh root@${crate} tar xzf - -C /opt < "$TARBALL"
    ssh root@${crate} "
        mkdir -p /var/opt/afc-epics-ioc &&
        chown -R ${USER} /var/opt/afc-epics-ioc &&
        cd /opt/afc-epics-ioc &&
        cp service/95-afc.rules /etc/udev/rules.d &&
        cp service/afc-ioc@.service /etc/systemd/system &&
        cp bin/linux-x86_64/decode-reg /usr/local/bin &&
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
