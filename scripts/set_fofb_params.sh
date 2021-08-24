#!/usr/bin/env bash

CRATES=()
CRATES+=("IA-01RaBPM-CO-IOCSrv")
CRATES+=("IA-02RaBPM-CO-IOCSrv")
CRATES+=("IA-03RaBPM-CO-IOCSrv")
CRATES+=("IA-04RaBPM-CO-IOCSrv")
CRATES+=("IA-05RaBPM-CO-IOCSrv")
#CRATES+=("IA-06RaBPM-CO-IOCSrv")
CRATES+=("IA-07RaBPM-CO-IOCSrv")
#CRATES+=("IA-08RaBPM-CO-IOCSrv")
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
#CRATES+=("IA-20RaBPMTL-CO-IOCSrv")

for crate in "${CRATES[@]}"; do

    crate_num=$(echo ${crate} | grep -o "[0-9][0-9]" | sed 's/^0*//')
    echo "Crate: ${crate}" && \
    SSHPASS=root sshpass -e ssh -o StrictHostKeyChecking=no root@${crate} bash -c "\
        cd && \
        for board in 7 9; do
            printf \"Configuring BPM board: %s\n\" \"\${board}\"
            for dcc in \$(seq 0 1); do
                num_gts=8
        
                if [ \${dcc} = 1 ] && [ \${board} != 7 ]; then
                    continue
                fi

                printf "DCC: %s\n" "\${dcc}"
                (fofb_ctrl --verbose --num_gts \${num_gts} --brokerendp ipc:///tmp/malamute --boardslot \${board} --halcsnumber \${dcc} --bpm_id \$(((${crate_num}-1)*8+i\${board}*2+\${dcc})) --time_frame_len 5000 --cc_enable 0)
        
                (fofb_ctrl --verbose --num_gts \${num_gts} --brokerendp ipc:///tmp/malamute --boardslot \${board} --halcsnumber \${dcc} --cc_enable 1)
                # old gateware
                (trigger --brokerendp ipc:///tmp/malamute --boardslot \${board} --halcsnumber \${dcc} --channumber 2 --rcvsrc 0 --rcvsel 5)
                # new bpm gateware
                (trigger --brokerendp ipc:///tmp/malamute --boardslot \${board} --halcsnumber \${dcc} --channumber 20 --rcvsrc 0 --rcvsel 5)
                (fofb_ctrl --verbose --num_gts \${num_gts} -b ipc:///tmp/malamute --boardslot \${board} --halcsnumber \${dcc} --link_partners)
            done;
        done;
        "
done
