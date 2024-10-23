#!/usr/bin/env bash

. crate_list.sh

for crate in "${CRATES[@]}"; do
    ssh root@${crate} reboot
done
