'''This file includes Sirius specific information, like:
  - PV naming rules
  - which slots are in use on which crates

Author: Érico Nogueira
'''

from bpm_app.bpm_slot_mapping import area_prefix, device_prefix
from bpm_app.pvs import create_pv

# crate information
_tl_crate = 21
_homolog_crate = 22
_devel_crate = 23

# slot numbers are (physical_slot*2-1) and (physical_slot*2)

# general slot information
rtmlamp_slot = 3
first_si_bpm_slot = 13

# default slots in storage ring
_si_slots = list(range(first_si_bpm_slot, 21))

# crates where the ID (insertion device) BPMs are installed
_extra_si_slots = [11, 12]
_extra_si_slots_crates = ['06', '07', '08', '09', '10', '11', '12', '14']

# crates where XBPMs are installed
_xbpm4_slots = [7, 8]
_xbpm5_slots = [9, 10]
_xbpm_slots_crates = {
        '06': _xbpm4_slots,
        '07': _xbpm4_slots,
        '08': _xbpm4_slots,
        '09': _xbpm4_slots,
        '10': _xbpm5_slots,
        '11': _xbpm4_slots,
        '12': _xbpm4_slots,
        '13': _xbpm5_slots,
        '14': _xbpm4_slots,
}

# default and extra slots in booster ring
_booster_slots = [21, 22]
_extra_booster_slots = [23]
_extra_booster_slots_crates = ['02', '04', '06', '08', '10', '12', '14', '16', '18', '20']

_tl_slots = list(range(11, 22))

def crate_number(n):
	return f"{int(n):02}"

def get_key(crate, slot):
	return crate_number(crate), str(slot)

si_bpm_slots = {}
bo_bpm_slots = {}
all_bpm_slots = {}
pbpm_slots = {
    '06': [7, 8],
    '07': [7, 8],
    '08': [7, 8],
    '09': [7, 8],
    '10': [9, 10],
    '11': [7, 8],
    '12': [7, 8],
    '13': [9, 10],
    '14': [7, 8],
}

fofb_cc_slots = {}

for crate_n in range(1, 24):
	crate = crate_number(crate_n)

	if crate_n != _tl_crate:
		si_bpm_slots[crate] = _si_slots + (_extra_si_slots if crate in _extra_si_slots_crates else [])

		if crate_n < _tl_crate:
			bo_bpm_slots[crate] = _booster_slots + (_extra_booster_slots if crate in _extra_booster_slots_crates else [])

		all_bpm_slots[crate] = si_bpm_slots[crate] + bo_bpm_slots.get(crate, []) + _xbpm_slots_crates.get(crate, [])

		fofb_cc_slots[crate] = [rtmlamp_slot] + all_bpm_slots[crate]
	else:
		all_bpm_slots[crate] = _tl_slots

def get_pv_prefix(crate, slot):
	if slot == rtmlamp_slot:
		if int(crate) < _homolog_crate:
			pv_prefix = "IA-" + crate + "RaBPM:BS-FOFBCtrl:"
		else:
			pv_prefix = "DE-" + crate + f"SL11" + ":BS-FOFBCtrl:"
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

rtmlamp_channels = ['M1:PS-FCH:', 'M1:PS-FCV:', 'M2:PS-FCH:', 'M2:PS-FCV:', 'C2:PS-FCH:', 'C2:PS-FCV:', 'C3:PS-FCH:', 'C3:PS-FCV:']
rtmlamp_channels += [f'XX:PS-FC{i:02}:' for i in range(8, 12)]

def get_rtmlamp_prefix(crate, channel):
	return f'SI-{crate_number(crate)}{channel}'
