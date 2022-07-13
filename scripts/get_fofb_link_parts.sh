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

for crate in "${CRATES[@]}"; do

    echo "${crate}" && \
    SSHPASS=lnls-bpm sshpass -e ssh -o StrictHostKeyChecking=no lnls-bpm@${crate} bash -c "\
        set -x > /dev/null && \
	echo \"P2P:\" && \
        fofb_ctrl --verbose --num_gts 8 --brokerendp ipc:///tmp/malamute --boardslot 2 --halcsnumber 1 --bpm_cnt && \
        fofb_ctrl --verbose --num_gts 8 --brokerendp ipc:///tmp/malamute --boardslot 2 --halcsnumber 1 --link_partners && \
	echo \"FMC:\" && \
        fofb_ctrl --verbose --num_gts 8 --brokerendp ipc:///tmp/malamute --boardslot 2 --halcsnumber 0 --bpm_cnt && \
        fofb_ctrl --verbose --num_gts 4 --brokerendp ipc:///tmp/malamute --boardslot 2 --halcsnumber 0 --link_partners"

    echo ""

done
