#!/bin/python

import re
import pandas as pd
from os import listdir
from os.path import exists

repairs='experiments/repairs'
repairs_out='experiments/repairs.csv'

repair_data = {
    'ontology': [],
    'failed': [],
    'failed_repair': [],
    'steps': [],
    'time': [],
    'calls': [],
    'iic_mcs': [],
    'iic_remove': [],
    'inf_mcs': [],
    'inf_weakening': [],
    'inf_remove': [],
}

def read_run_info(onto: str, dir: str, failed: bool):
    repair_data['ontology'].append(onto)
    repair_data['failed'].append(failed)
    repair_data['failed_repair'].append(failed if exists(f'{dir}/repair-weakening.log') else None)
    if failed:
        repair_data['steps'].append(None)
        repair_data['time'].append(None)
        repair_data['calls'].append(None)
        repair_data['iic_mcs'].append(None)
        repair_data['iic_remove'].append(None)
        repair_data['inf_mcs'].append(None)
        repair_data['inf_weakening'].append(None)
        repair_data['inf_remove'].append(None)
    else:
        with open(f'{dir}/repair-weakening.log') as log:
            text = log.read()
            assert text.count('Finished repairing the ontology.') == 1
            repair_data['steps'].append(text.count('Selected the weaker axiom'))
            matched = re.search('Done. \\(([0-9]+) ms; ([0-9]+) reasoner calls\\)', text)
            assert matched is not None
            repair_data['time'].append(int(matched.group(1)))
            repair_data['calls'].append(int(matched.group(2)))
        if exists(f'{dir}/eval.txt'):
            with open(f'{dir}/eval.txt') as eval:
                text = eval.read()
                matched = re.search('[^;]+/repair-weakening.owl;([0-9]+);[^;]+/repair-mcs.owl;([0-9]+);([.0-9eE+-]+)', text)
                assert matched is not None
                iic = float(matched.group(3))
                assert 0 <= iic and iic <= 1
                repair_data['iic_mcs'].append(iic)
                repair_data['inf_mcs'].append(int(matched.group(2)))
                repair_data['inf_weakening'].append(int(matched.group(1)))
        else:
            repair_data['iic_mcs'].append(None)
            repair_data['inf_mcs'].append(None)
            repair_data['inf_weakening'].append(None)
        if exists(f'{dir}/reval.txt'):
            with open(f'{dir}/reval.txt') as eval:
                text = eval.read()
                matched = re.search('[^;]+/repair-weakening.owl;([0-9]+);[^;]+/repair-remove.owl;([0-9]+);([.0-9eE+-]+)', text)
                assert matched is not None
                iic = float(matched.group(3))
                assert 0 <= iic and iic <= 1
                repair_data['iic_remove'].append(iic)
                repair_data['inf_remove'].append(int(matched.group(2)))
        else:
            repair_data['iic_remove'].append(None)
            repair_data['inf_remove'].append(None)

for onto in listdir(repairs):
    if not onto.startswith('.'):
        for run in listdir(f'{repairs}/{onto}'):
            if not run.startswith('.'):
                read_run_info(onto, f'{repairs}/{onto}/{run}', False)
        for run in listdir(f'{repairs}/{onto}/.failed'):
            if not run.startswith('.'):
                read_run_info(onto, f'{repairs}/{onto}/.failed/{run}', True)
df = pd.DataFrame(repair_data)
df.to_csv(repairs_out)

