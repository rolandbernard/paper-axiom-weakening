#!/bin/python

import re
import pandas as pd
from os import listdir
from os.path import exists

cache='experiments/cache'
cache_out='experiments/cache.csv'

cache_data = {
    'ontology': [],
    'reasoner': [],
    'size': [],
    'type': [],
    'time': [],
    'calls': [],
}

def read_run_info(onto: str, run: str, file: str):
    matched = re.match('([^-]+)-([0-9]+)(-([^.]+))?.txt', run)
    assert matched is not None
    reasoner = matched.group(1)
    size = int(matched.group(2))
    type = matched.group(4) or 'full'
    with open(f'{file}') as log:
        text = log.read()
        regex = re.compile('Done. \\(([0-9]+) ms; ([0-9]+) reasoner calls\\)')
        matches = regex.findall(text)
        assert matches
        for match in matches:
            cache_data['ontology'].append(onto)
            cache_data['reasoner'].append(reasoner)
            cache_data['size'].append(size)
            cache_data['type'].append(type)
            cache_data['time'].append(int(match[0]) / size)
            cache_data['calls'].append(int(match[1]) / size)

for onto in listdir(cache):
    if not onto.startswith('.'):
        for run in listdir(f'{cache}/{onto}'):
            if not run.startswith('.'):
                read_run_info(onto, run, f'{cache}/{onto}/{run}')
df = pd.DataFrame(cache_data)
df.to_csv(cache_out)
