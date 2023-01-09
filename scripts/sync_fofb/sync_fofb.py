#!/usr/bin/env python3

'''Script to configure FOFB_CC cores across FOFB and BPM AFCs

Receives as argument each crate number we are interested in configuring.

Author: Melissa Aguiar
Modified by: Érico Nogueira, Guilherme Ricioli
'''

from itertools import chain, product
from time import sleep
from epics import PV
import collections
import numpy as np
import sys

from bpm_slot_mapping import area_prefix, device_prefix

# configurable options
time_frame_len_val = 2100

# fixed options
fofb_ctrl_offs = 480
trigger_chans = [1, 2, 20]

# format crate numbers taken from CLI args
crates = [f"{int(i):02}" for i in sys.argv[1:]]

# slot information
rtmlamp_slot = 3
# FOFB and BPMs slot numbers (physical_slot*2-1 and physical_slot*2)
slots = [rtmlamp_slot, 13, 14, 15, 16, 17, 18, 19, 20]

# crates where the ID (insertion device) BPM boards are installed
extra_slots = [11, 12]
extra_slots_crates = ['06', '07', '08', '09', '10', '11', '12', '21']

# devices whose CC core will be enabled:
# we only need M1/M2 and C2/C3-1 for normal operation
cc_enable_crates = crates
cc_enable_slots = [rtmlamp_slot, 13, 14, 17, 18]
# exception for faulty crate:
def cc_enable_exception(slot, crate):
	return False

def consume(iterator):
	collections.deque(iterator, maxlen=0)

global_pv_list = []
def create_pv(name):
	pv = PV(name)
	global_pv_list.append(pv)
	return pv

def pv_prefix_gen(slot, crate):
	pv_prefix = ""
	if slot == rtmlamp_slot:
		# board connected to physical slot 2 == RTMLAMP
		pv_prefix = "IA-" + crate + "RaBPM:BS-FOFBCtrl:"
	else:
		key = (crate, str(slot))
		pv_prefix += area_prefix[key]
		pv_prefix += device_prefix[key]

	return pv_prefix

def fofb_ctrl_pv_list_gen(name, slot, crate):
	pv_prefix = pv_prefix_gen(slot, crate)
	pv_list = [create_pv(pv_prefix + "DCCP2P" + name)]
	if slot == rtmlamp_slot:
		# has additional FOFB_CC core
		pv_list.append(create_pv(pv_prefix + "DCCFMC" + name))

	return pv_list

def wait_pv(pv_list):
	waiting = True
	while waiting:
		sleep(0.001)
		waiting = not all((pv.put_complete for pv in pv_list))

def put_pv(pv_list, value, wait=True, check=True):
	for pv in pv_list:
		print(f"Writing '{value}' into '{pv.pvname}'...")
		pv.put(value, use_complete=True)
	if wait:
		wait_pv(pv_list)

		if check:
			for pv in pv_list:
				assert(pv.get() == value)

cc_enable = []
cc_enable_one = []
time_frame_len = []
rcv_src = []
rcv_in_sel = []

bpm_id_list = []
bpm_id = {}

bpm_cnt = []

for crate in crates:
	if crate in extra_slots_crates:
		current_slots = slots + extra_slots
	else:
		current_slots = slots
	
	for slot in current_slots:
		key = (crate, slot)

		cc_enable_k = fofb_ctrl_pv_list_gen("CCEnable-SP", slot, crate)
		cc_enable.extend(cc_enable_k)
		if crate in cc_enable_crates and slot in cc_enable_slots or cc_enable_exception(slot, crate):
			cc_enable_one.extend(cc_enable_k)
		time_frame_len.extend(fofb_ctrl_pv_list_gen("TimeFrameLen-SP", slot, crate))

		bpm_id[key] = fofb_ctrl_pv_list_gen("BPMId-SP", slot, crate)
		bpm_id_list.extend(bpm_id[key])

		pv_prefix = pv_prefix_gen(slot, crate)
		if slot != rtmlamp_slot:
			for trigger in trigger_chans:
				rcv_src.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvSrc-Sel")])
				rcv_in_sel.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvInSel-SP")])

		if slot == rtmlamp_slot and crate in cc_enable_crates:
			bpm_cnt.extend(fofb_ctrl_pv_list_gen("BPMCnt-Mon", slot, crate))

print("Connecting to all PVs...")
consume((pv.wait_for_connection() for pv in global_pv_list))

print("Disabling DCC and configuring TimeFrameLen...")
put_pv(cc_enable, 0)
put_pv(time_frame_len, time_frame_len_val, wait=False)

for key in product(crates, slots):
	crate, slot = key
	print(f"Writing BPM IDs for {crate}...")

	bpm_id_value = None
	phys_slot = (slot + 1) // 2
	if slot == rtmlamp_slot:
		bpm_id_value = fofb_ctrl_offs + int(crate) - 1
	else:
		bpm_id_value = 8*(int(crate) - 1) + 2*(phys_slot - 7)

	put_pv(bpm_id[key], bpm_id_value, wait=False)

wait_pv(chain(time_frame_len, bpm_id_list))

print("Enabling DCC and configuring timer muxes...")
put_pv(cc_enable_one, 1)

put_pv(rcv_src, 0, wait=False)
put_pv(rcv_in_sel, 5, wait=False)
wait_pv(chain(rcv_src, rcv_in_sel))

print("Sending trigger event...")
evg_evt10 = PV("AS-RaMO:TI-EVG:Evt10ExtTrig-Cmd")
# doesn't return "ON"
put_pv([evg_evt10], "ON", check=False)

sleep(1)
for pv in bpm_cnt:
	print(f"{pv.pvname}: {pv.get(use_monitor=False)}")
