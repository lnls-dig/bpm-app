#!/usr/bin/env bash

BPMS=("BO-01U:DI-BPM:ACQStatus-Sts" "BO-02U:DI-BPM:ACQStatus-Sts" "BO-03U:DI-BPM:ACQStatus-Sts" "BO-04U:DI-BPM:ACQStatus-Sts" "BO-05U:DI-BPM:ACQStatus-Sts" "BO-06U:DI-BPM:ACQStatus-Sts" "BO-07U:DI-BPM:ACQStatus-Sts" "BO-08U:DI-BPM:ACQStatus-Sts" "BO-09U:DI-BPM:ACQStatus-Sts" "BO-10U:DI-BPM:ACQStatus-Sts" "BO-11U:DI-BPM:ACQStatus-Sts" "BO-12U:DI-BPM:ACQStatus-Sts" "BO-13U:DI-BPM:ACQStatus-Sts" "BO-14U:DI-BPM:ACQStatus-Sts" "BO-15U:DI-BPM:ACQStatus-Sts" "BO-16U:DI-BPM:ACQStatus-Sts" "BO-17U:DI-BPM:ACQStatus-Sts" "BO-18U:DI-BPM:ACQStatus-Sts" "BO-19U:DI-BPM:ACQStatus-Sts" "BO-20U:DI-BPM:ACQStatus-Sts" "BO-21U:DI-BPM:ACQStatus-Sts" "BO-22U:DI-BPM:ACQStatus-Sts" "BO-23U:DI-BPM:ACQStatus-Sts" "BO-24U:DI-BPM:ACQStatus-Sts" "BO-25U:DI-BPM:ACQStatus-Sts" "BO-26U:DI-BPM:ACQStatus-Sts" "BO-27U:DI-BPM:ACQStatus-Sts" "BO-28U:DI-BPM:ACQStatus-Sts" "BO-29U:DI-BPM:ACQStatus-Sts" "BO-30U:DI-BPM:ACQStatus-Sts" "BO-31U:DI-BPM:ACQStatus-Sts" "BO-32U:DI-BPM:ACQStatus-Sts" "BO-33U:DI-BPM:ACQStatus-Sts" "BO-34U:DI-BPM:ACQStatus-Sts" "BO-35U:DI-BPM:ACQStatus-Sts" "BO-36U:DI-BPM:ACQStatus-Sts" "BO-37U:DI-BPM:ACQStatus-Sts" "BO-38U:DI-BPM:ACQStatus-Sts" "BO-39U:DI-BPM:ACQStatus-Sts" "BO-40U:DI-BPM:ACQStatus-Sts" "BO-41U:DI-BPM:ACQStatus-Sts" "BO-42U:DI-BPM:ACQStatus-Sts" "BO-43U:DI-BPM:ACQStatus-Sts" "BO-44U:DI-BPM:ACQStatus-Sts" "BO-45U:DI-BPM:ACQStatus-Sts" "BO-46U:DI-BPM:ACQStatus-Sts" "BO-47U:DI-BPM:ACQStatus-Sts" "BO-48U:DI-BPM:ACQStatus-Sts" "BO-49U:DI-BPM:ACQStatus-Sts" "BO-50U:DI-BPM:ACQStatus-Sts" "TB-01:DI-BPM-1:ACQStatus-Sts" "TB-01:DI-BPM-2:ACQStatus-Sts" "TB-02:DI-BPM-1:ACQStatus-Sts" "TB-02:DI-BPM-2:ACQStatus-Sts" "TB-03:DI-BPM:ACQStatus-Sts" "TB-04:DI-BPM:ACQStatus-Sts")

while :
do
    for bpm in "${BPMS[@]}"; do
        status=$(caget -t ${bpm})
        if [ "${status}" == "Idle" ] || [ "${status}" == "Aborted" ] ; then
            bpm_put=$(echo ${bpm} | awk -F':' '{print $1 ":" $2 ":"}')
            caput ${bpm_put}ACQTriggerEvent-Sel start
        fi
    done
    
    sleep 4;
done
