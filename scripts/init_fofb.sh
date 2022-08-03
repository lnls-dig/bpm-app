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

PIDS=()

LOG_DIR=~/log
if [ -d ${LOG_DIR} ]
then
  rm ${LOG_DIR}/*;
else
  echo "Creating log folder (${LOG_DIR})"
  mkdir ${LOG_DIR}
fi

# Synchronizes BPMs and arms DCCs
for crate in "${CRATES[@]}"; do
  crate_number=$(echo ${crate} | sed -e "{s/IA-//;s/RaBPM-CO-IOCSrv//;s/^0//;}")

  echo "Synchronizing BPMs and arming DCCs of crate ${crate_number}"
  SSHPASS=root sshpass -e ssh -o StrictHostKeyChecking=no root@${crate} bash -c "\
    set -x > /dev/null && \
    cd /opt/epics/ioc/bpm-epics-ioc/scripts/ && \
    ./sync_bpms.sh 7,8,9,10 ${crate_number} && \
    cd /root/postinstall/apps/bpm-app/halcs/examples/scripts/ && \
    ./cfg_fofb.sh 7,8,9,10 1 8 ${crate_number} && \
    ./cfg_fofb.sh 2 2 8 ${crate_number}" > ${LOG_DIR}/sync_bpm_arm_dcc_${crate_number} &
  PIDS+=($!)

done

# Waits for each background process to finish
for pid in "${PIDS[@]}"; do
  wait ${pid}
done

caput AS-RaMO:TI-EVG:Evt10ExtTrig-Cmd ON

echo "FOFB initialized!"
