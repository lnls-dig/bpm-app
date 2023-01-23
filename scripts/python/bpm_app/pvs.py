'''Functions to handle PV objects in an efficient manner

Author: Érico Nogueira
'''

from epics import PV
from time import sleep, clock_gettime, CLOCK_MONOTONIC
import collections

timeout = 10

PVPair = collections.namedtuple('PVPair', ['sp', 'rb'])

# list of PV
_global_pv_list = []
def create_pv(name):
	sp = PV(name)
	if name.endswith('-SP'):
		rb = PV(name.removesuffix('SP') + 'RB')
	elif name.endswith('-Sel'):
		rb = PV(name.removesuffix('Sel') + 'Sts')
	else:
		# covers -Cmd and any other weird cases
		rb = None
	pv_pair = PVPair(sp, rb)

	_global_pv_list.append(sp)
	if rb is not None:
		_global_pv_list.append(rb)

	return pv_pair

def wait_for_pv_connection():
    for pv in _global_pv_list:
        if not pv.wait_for_connection(timeout=timeout):
            raise Exception(f'PV connection timeout: {pv.pvname}')

# list of ([PVPair], value)
_global_wait_list = []

def _wait_pv(wait_list):
	start_time = clock_gettime(CLOCK_MONOTONIC)
	waiting = True
	while waiting:
		sleep(0.001)
		waiting = not all((pv_pair.sp.put_complete for pv_list, _ in wait_list for pv_pair in pv_list))
		if waiting and clock_gettime(CLOCK_MONOTONIC) - start_time > timeout:
			for pv_list, _ in wait_list:
				for pv_pair in pv_list:
					if not pv_pair.sp.put_complete:
						print(f'Writing into {pv_pair.sp.pvname} taking too long...')
			raise Exception('PV write timeout')

	for pv_list, value in wait_list:
		if value is None:
			continue
		for pv_pair in pv_list:
			if pv_pair.rb is not None:
				assert pv_pair.rb.get() == value
			else:
				assert pv_pair.sp.get() == value

	if wait_list is _global_wait_list:
		_global_wait_list[:] = []

def wait_pv():
	_wait_pv(_global_wait_list)

def put_pv(pv_list, value, wait=True, check=True):
	for pv_pair in pv_list:
		print(f"Writing '{value}' into '{pv_pair.sp.pvname}'...")
		pv_pair.sp.put(value, use_complete=True)

	wait = (pv_list, value if check else None)

	if wait:
		_wait_pv([wait])
	else:
		_global_wait_list.append(wait)

def get_pv(pv_list, which='sp'):
	return [pv_pair.sp.get() if which == 'sp' else pv_pair.rb.get() for pv_pair in pv_list]

def print_pv(pv_list, which='sp'):
	for pv_pair in pv_list:
		if which == 'sp':
			pv = pv_pair.sp
		else:
			pv = pv_pair.rb
		print(f"{pv.pvname}: {pv.get(use_monitor=False)}")
