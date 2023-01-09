'''Functions to handle PV objects in an efficient manner

Author: Érico Nogueira
'''

from epics import PV
from time import sleep
import collections

def _consume(iterator):
	collections.deque(iterator, maxlen=0)

# list of PV
_global_pv_list = []
def create_pv(name):
	pv = PV(name)
	_global_pv_list.append(pv)
	return pv

def wait_for_pv_connection():
	_consume((pv.wait_for_connection() for pv in _global_pv_list))

# list of ([PV], value)
_global_wait_list = []

def _wait_pv(wait_list):
	waiting = True
	while waiting:
		sleep(0.001)
		waiting = not all((pv.put_complete for pv_list, _ in wait_list for pv in pv_list))

	for pv_list, value in wait_list:
		if value is None:
			continue
		for pv in pv_list:
			# TODO: look at readback PVs
			assert pv.get() == value

	if wait_list is _global_wait_list:
		_global_wait_list[:] = []

def wait_pv():
	_wait_pv(_global_wait_list)

def put_pv(pv_list, value, wait=True, check=True):
	for pv in pv_list:
		print(f"Writing '{value}' into '{pv.pvname}'...")
		pv.put(value, use_complete=True)

	wait = (pv_list, value if check else None)

	if wait:
		_wait_pv([wait])
	else:
		_global_wait_list.append(wait)
