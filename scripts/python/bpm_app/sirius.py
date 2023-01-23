'''This file includes Sirius specific information, like:
  - PV naming rules
  - which slots are in use on which crates

Author: Érico Nogueira
'''

from bpm_app.bpm_slot_mapping import area_prefix, device_prefix
from bpm_app.pvs import create_pv

# slot information
rtmlamp_slot = 3
# FOFB and BPMs slot numbers (physical_slot*2-1 and physical_slot*2)
_slots = [rtmlamp_slot, 13, 14, 15, 16, 17, 18, 19, 20]

# crates where the ID (insertion device) BPMs are installed
_extra_slots = [11, 12]
_extra_slots_crates = ['06', '07', '08', '09', '10', '11', '12', '21']

def crate_number(n):
	return f"{int(n):02}"

def get_key(crate, slot):
	return crate_number(crate), str(slot)

slots_by_crate = {}
for crate_n in range(1, 23):
	crate = crate_number(crate_n)
	slots_by_crate[crate] = _slots + (_extra_slots if crate in _extra_slots_crates else [])

def get_pv_prefix(crate, slot):
	if slot == rtmlamp_slot:
		# board connected to physical slot 2 == RTMLAMP
		pv_prefix = "IA-" + crate + "RaBPM:BS-FOFBCtrl:"
	else:
		key = get_key(crate, slot)
		pv_prefix = area_prefix[key] + device_prefix[key]

	return pv_prefix

def get_fofb_cc_pv_list(name, crate, slot):
	pv_prefix = get_pv_prefix(crate, slot)
	pv_list = [create_pv(pv_prefix + "DCCP2P" + name)]
	if slot == rtmlamp_slot:
		# has additional FOFB_CC core
		pv_list.append(create_pv(pv_prefix + "DCCFMC" + name))

	return pv_list
