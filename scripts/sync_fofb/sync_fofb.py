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

import bpm_epics_ioc_slot_mapping

rtmlamp_slot = 3
fofb_ctrl_offs = 480

crates = [f"{int(i):02}" for i in sys.argv[1:]]
# FOFB and BPMs slot number (physical_slot*2-1)

# XXX: is this slot sequence correct?
slots = [rtmlamp_slot, 13, 15, 17, 19]

trigger_chans = [1, 2, 20]

time_frame_len_val = 5000

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
		key_prefix = "CRATE_" + str(crate) + "_BPM_" + str(slot)
		pv_prefix += bpm_epics_ioc_slot_mapping.area_prefix_dict[key_prefix + "_PV_AREA_PREFIX"]
		pv_prefix += bpm_epics_ioc_slot_mapping.device_prefix_dict[key_prefix + "_PV_DEVICE_PREFIX"]

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
time_frame_len = []
rcv_src = []
rcv_in_sel = []

bpm_id_list = []
bpm_id = {}

for key in product(crates, slots):
	crate, slot = key

	cc_enable.extend(fofb_ctrl_pv_list_gen("CCEnable-SP", slot, crate))
	time_frame_len.extend(fofb_ctrl_pv_list_gen("TimeFrameLen-SP", slot, crate))

	bpm_id[key] = fofb_ctrl_pv_list_gen("BPMId-SP", slot, crate)
	bpm_id_list.extend(bpm_id[key])

	pv_prefix = pv_prefix_gen(slot, crate)
	if slot != rtmlamp_slot:
		for trigger in trigger_chans:
			rcv_src.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvSrc-Sel")])
			rcv_in_sel.extend([create_pv(pv_prefix + "TRIGGER" + str(trigger) + "RcvInSel-SP")])

consume((pv.wait_for_connection() for pv in global_pv_list))

put_pv(cc_enable, 0)
put_pv(time_frame_len, time_frame_len_val, wait=False)

for key in product(crates, slots):
	crate, slot = key
	print(f"Configuring crate {crate}...")

	bpm_id_value = None
	phys_slot = (slot + 1) // 2
	if slot == rtmlamp_slot:
		bpm_id_value = fofb_ctrl_offs + int(crate) - 1
	else:
		bpm_id_value = 8*(int(crate) - 1) + 2*(phys_slot - 7)

	put_pv(bpm_id[key], bpm_id_value, wait=False)

wait_pv(chain(time_frame_len, bpm_id_list))

put_pv(cc_enable, 1)

put_pv(rcv_src, 0, wait=False)
put_pv(rcv_in_sel, 5, wait=False)
wait_pv(chain(rcv_src, rcv_in_sel))

evg_evt10 = PV("AS-RaMO:TI-EVG:Evt10ExtTrig-Cmd")
evg_evt10.put("ON", wait=True)
