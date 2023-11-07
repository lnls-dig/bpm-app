'''Functions to handle PV objects in an efficient manner

Author: Érico Nogueira
'''

from epics import PV
from time import sleep, clock_gettime, CLOCK_MONOTONIC
import collections
import math

timeout = 10

PVPair = collections.namedtuple('PVPair', ['sp', 'rb'])

# list of PV
_global_pv_list = []
def create_pv(name, **kwargs):
	sp = PV(name, **kwargs)
	if name.endswith('-SP'):
		rb = PV(name.replace('-SP','-RB'), **kwargs)
	elif name.endswith('-Sel'):
		rb = PV(name.replace('-Sel','-Sts'), **kwargs)
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
		waiting = not all((pv_pair.sp.put_complete for pv_list, _, _ in wait_list for pv_pair in pv_list))
		if waiting and clock_gettime(CLOCK_MONOTONIC) - start_time > timeout:
			for pv_list, _, _ in wait_list:
				for pv_pair in pv_list:
					if not pv_pair.sp.put_complete:
						print(f'Writing into {pv_pair.sp.pvname} taking too long...')
			raise Exception('PV write timeout')

	for pv_list, value, precision in wait_list:
		if value is None:
			continue
		for pv_pair in pv_list:
			if pv_pair.rb is not None:
				read_pv = pv_pair.rb
			else:
				read_pv = pv_pair.sp
			check_fn = (lambda x: math.isclose(x, value, rel_tol=precision)) if isinstance(value, float) else lambda x: x == value
			for i in range(10):
				if check_fn(read_pv.get(use_monitor=False)):
					break
				sleep(.1)
			else:
				print(f'Read from {read_pv.pvname} not matching write into {pv_pair.sp.pvname}')
				raise Exception('PV value mismatch')

	if wait_list is _global_wait_list:
		_global_wait_list[:] = []

def wait_pv():
	_wait_pv(_global_wait_list)

def put_pv(pv_list, value, wait=True, check=True, verbose=True, precision=0.1):
	for pv_pair in pv_list:
		if verbose:
			print(f"Writing '{value}' into '{pv_pair.sp.pvname}'...")
		pv_pair.sp.put(value, use_complete=True)

	wait_list = (pv_list, value if check else None, precision)

	if wait:
		_wait_pv([wait_list])
	else:
		_global_wait_list.append(wait_list)

def get_pv(pv_list, which='sp'):
	return [pv_pair.sp.get() if which == 'sp' else pv_pair.rb.get() for pv_pair in pv_list]

def print_pv(pv_list, which='sp'):
	for pv_pair in pv_list:
		if which == 'sp':
			pv = pv_pair.sp
		else:
			pv = pv_pair.rb
		print(f"{pv.pvname} {pv.get(use_monitor=False)}")
