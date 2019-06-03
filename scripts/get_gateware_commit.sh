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

LOGS=()
LOGS+=("halcsd4_be0.log")
LOGS+=("halcsd5_be0.log")
LOGS+=("halcsd6_be0.log")
LOGS+=("halcsd7_be0.log")
LOGS+=("halcsd8_be0.log")
LOGS+=("halcsd9_be0.log")
LOGS+=("halcsd10_be0.log")
LOGS+=("halcsd11_be0.log")
LOGS+=("halcsd12_be0.log")

for crate in "${CRATES[@]}"; do

    echo "Crate: ${crate}" && \
    SSHPASS=lnls-bpm sshpass -e ssh -o StrictHostKeyChecking=no lnls-bpm@${crate} bash -c "\
        cd && \
        for log in "${LOGS[@]}"; do
            if [ -f /var/log/halcs/\${log} ]; then 
                COMMIT=\$(cat /var/log/halcs/\${log} | grep \"commit-id:\" | head -n 1)
		[ ! -z \"\${COMMIT}\" ] && (echo -n \"\${log}: \" && echo \${COMMIT});
	    fi
        done"
done
