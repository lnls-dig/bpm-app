#!/usr/bin/env bash

set -e

. crate_list.sh

for crate in "${CRATES[@]}"; do
    ssh root@${crate} "
        echo $crate &&
        yum -y install docker docker-compose &&
        sed -i s/--selinux-enabled/--selinux-enabled=false/ /etc/sysconfig/docker &&
        systemctl enable --now docker" &
done
