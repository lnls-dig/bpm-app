#!/usr/bin/env python3

'''Script to configure FOFB_CC cores across FOFB and BPM AFCs

Receives as argument each crate number we are interested in configuring.

Author: Melissa Aguiar
Modified by: Érico Nogueira, Guilherme Ricioli
'''

from itertools import product
from time import sleep
import numpy as np
import sys

from pvs import create_pv, wait_for_pv_connection, wait_pv, put_pv, print_pv
from sirius import rtmlamp_slot, slots_by_crate, crate_number, get_pv_prefix, get_fofb_cc_pv_list

# configurable options
time_frame_len_val = 2100

# fixed options
fofb_ctrl_offs = 480
trigger_chans = [1, 2, 20]

# format crate numbers taken from CLI args
crates = [crate_number(i) for i in sys.argv[1:]]

# devices whose CC core will be enabled:
# we only need M1/M2 and C2/C3-1 for normal operation
cc_enable_crates = crates
cc_enable_slots = [rtmlamp_slot, 13, 14, 17, 18]
# exception for faulty crate:
def cc_enable_exception(crate, slot):
	return False

cc_enable = []
cc_enable_one = []
time_frame_len = []
rcv_src = []
rcv_in_sel = []

bpm_id_list = []
bpm_id = {}

bpm_cnt = []

for crate in crates:
	for slot in slots_by_crate[crate]:
		key = (crate, slot)

		cc_enable_k = get_fofb_cc_pv_list("CCEnable-SP", crate, slot)
		cc_enable.extend(cc_enable_k)
		if crate in cc_enable_crates and slot in cc_enable_slots or cc_enable_exception(slot, crate):
			cc_enable_one.extend(cc_enable_k)
		time_frame_len.extend(get_fofb_cc_pv_list("TimeFrameLen-SP", crate, slot))

		bpm_id[key] = get_fofb_cc_pv_list("BPMId-SP", crate, slot)
		bpm_id_list.extend(bpm_id[key])

		if slot != rtmlamp_slot:
			pv_prefix = get_pv_prefix(crate, slot)
			for trigger in trigger_chans:
				rcv_src.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvSrc-Sel")])
				rcv_in_sel.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvInSel-SP")])

		if slot == rtmlamp_slot and crate in cc_enable_crates:
			bpm_cnt.extend(get_fofb_cc_pv_list("BPMCnt-Mon", crate, slot))

evg_evt10 = create_pv("AS-RaMO:TI-EVG:Evt10ExtTrig-Cmd")

print("Connecting to all PVs...")
wait_for_pv_connection()

print("Disabling DCC and configuring TimeFrameLen...")
put_pv(cc_enable, 0)
put_pv(time_frame_len, time_frame_len_val, wait=False)

for crate in crates:
	for slot in slots_by_crate[crate]:
		key = (crate, slot)
		print(f"Writing BPM IDs for {crate}...")

		bpm_id_value = None
		phys_slot = (slot + 1) // 2
		if slot == rtmlamp_slot:
			bpm_id_value = fofb_ctrl_offs + int(crate) - 1
		else:
			bpm_id_value = 8*(int(crate) - 1) + 2*(phys_slot - 7)

		put_pv(bpm_id[key], bpm_id_value, wait=False)

wait_pv()

print("Enabling DCC and configuring timer muxes...")
put_pv(cc_enable_one, 1)

put_pv(rcv_src, 0, wait=False)
put_pv(rcv_in_sel, 5, wait=False)
wait_pv()

print("Sending trigger event...")
# doesn't return "ON"
put_pv([evg_evt10], "ON", check=False)

sleep(1)
print_pv(bpm_cnt)
