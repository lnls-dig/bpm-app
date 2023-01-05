#!/usr/bin/env python3

import json
import requests

requests.packages.urllib3.disable_warnings()

base_url = 'https://ais-eng-srv-ta.cnpem.br/mgmt/'
bpl = base_url + 'bpl/'

def login():
    with open('credentials.json', 'r') as f:
        # format: {"username": "<username>", "password": "<password>"}
        credentials = json.load(f)

    session = requests.Session()
    response = session.post(bpl + 'login', data=credentials, verify=False)

    if ('authenticated' in response.text):
        return session

session = login()

# utility functions using requests

def query(endpoint, **kwargs):
    url = bpl + endpoint
    resp = session.get(url, params=kwargs)
    resp.raise_for_status()
    return resp.json()

def command(endpoint, **kwargs):
    url = bpl + endpoint
    resp = session.get(url, params=kwargs)
    if resp.status_code != 200:
        print(resp.text)
    resp.raise_for_status()
    return resp

# utility functions for dealing with pv lists

def print_pvs(pvs):
    print([pv['pvName'] for pv in pvs])

def list_into_comma(l):
    return ','.join(l)

# functions using the actual API

def get_pvs(pv):
    return query('getPVStatus', pv=pv)

def fix_monitored_pvs(pv):
    pvs = get_pvs(pv)
    monitored_pvs = []
    for pv in pvs:
        if pv['isMonitored'] == 'true':
            monitored_pvs.append(pv)
    for pv in monitored_pvs:
        command('changeArchivalParameters', pv=pv['pvName'], samplingperiod=pv['samplingPeriod'], samplingmethod='SCAN')

def archive_pv(pv, samplingperiod):
    return command('archivePV', pv=pv, samplingperiod=samplingperiod, samplingmethod='SCAN', policy='Default')

def pause_pv(pv):
    return command('pauseArchivingPV', pv=pv)

def resume_pv(pv):
    return command('resumeArchivingPV', pv=pv)

def delete_pv(pv):
    return command('deletePV', pv=pv, deleteData='true')

def rename_pv(old_pv, new_pv):
    return command('renamePV', pv=old_pv, newname=new_pv)

# complex functions for dealing with files with PV lists
# the format is "<PV name>[ <sampling period>]"

def dump_pvs_to_file(pv, file):
    pvs = get_pvs(pv)
    with open(file, 'w') as f:
        f.writelines((f'{pv["pvName"]} {pv.get("samplingPeriod", None)}\n' for pv in pvs))

def archive_pvs_from_file(file):
    # initialize with the most common one
    pvs_by_sampling = {'0.1': []}
    all_pvs = []

    with open(file, 'r') as f:
        for l in f:
            ls = l.strip().split(' ')
            all_pvs.append(ls[0])

            if len(ls) == 2:
                n = float(ls[1]) # check that it is a number
                if pvs_by_sampling.get(ls[1]) is None:
                    pvs_by_sampling[ls[1]] = []
                pvs_by_sampling[ls[1]].append(ls[0])
            else:
                pvs_by_sampling['0.1'].append(ls[0])

    all_pvs_status = get_pvs(list_into_comma(all_pvs))
    for pv in all_pvs_status:
        if pv['status'] != 'Not being archived':
            raise Exception(f'{pv["pvName"]} is already being archived!')

    for samplingperiod in pvs_by_sampling:
        archive_pv(list_into_comma(pvs_by_sampling[samplingperiod]), samplingperiod)
