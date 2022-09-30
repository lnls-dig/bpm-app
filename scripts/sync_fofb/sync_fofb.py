#!/usr/bin/env python3

'''Script to configure FOFB_CC cores across FOFB and BPM AFCs

Receives as argument each crate number we are interested in configuring.

Author: Melissa Aguiar
Modified by: Érico Nogueira, Guilherme Ricioli
'''

from time import sleep
from epics import PV
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
	pv_list = [PV(pv_prefix + "P2P:" + name)]
	if slot == rtmlamp_slot:
		# has additional FOFB_CC core
		pv_list.append(PV(pv_prefix + "FMC:" + name))

	for pv in pv_list:
		success = pv.wait_for_connection(5)
		if not success:
			raise RuntimeError(f"connection to '{pv.pvname}' wasn't successful")

	return pv_list

def put_pv(pv_list, value):
	for pv in pv_list:
		print(f"Writing '{value}' into '{pv.pvname}'...")
		pv.put(value, wait=True)
		# FIXME: sleep added because CCEnable wasn't being updated fast enough for some reason
		sleep(.3)
        # TODO: check -RB instead
		new_value = pv.get()
		if new_value != value:
			print(f"{pv.info}")
			raise RuntimeError(f"writing into '{pv.pvname}' wasn't successful: '{new_value}' != '{value}'")

for crate in crates:
	print(f"Configuring crate {crate}...")

	for slot in slots:
		pv_prefix = pv_prefix_gen(slot, crate)
		phys_slot = (slot + 1) // 2

		cc_enable = fofb_ctrl_pv_list_gen("CCEnable-SP", slot, crate)
		bpm_id = fofb_ctrl_pv_list_gen("BPMId-SP", slot, crate)
		time_frame_len = fofb_ctrl_pv_list_gen("TimeFrameLen-SP", slot, crate)

		put_pv(cc_enable, 0)

		put_pv(time_frame_len, 5000)

		bpm_id_value = None
		if slot == rtmlamp_slot:
			bpm_id_value = fofb_ctrl_offs + int(crate) - 1
		else:
			bpm_id_value = 8*(int(crate) - 1) + 2*(phys_slot - 7)
		put_pv(bpm_id, bpm_id_value)

		put_pv(cc_enable, 1)

		if slot != rtmlamp_slot:
			for trigger in trigger_chans:
				rcv_src = [PV(pv_prefix + "TRIGGER" + str(trigger) + "RcvSrc-Sel")]
				rcv_in_sel = [PV(pv_prefix + "TRIGGER" + str(trigger) + "RcvInSel-SP")]
				put_pv(rcv_src, 0)
				put_pv(rcv_in_sel, 5)

evg_evt10 = PV("AS-RaMO:TI-EVG:Evt10ExtTrig-Cmd")
evg_evt10.put("ON", wait=True)
