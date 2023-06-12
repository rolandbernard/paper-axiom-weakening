#!/bin/bash
# Given the ontologies as input, test their information distribution.

ontos=$@

function run-experiment() {
    onto=$1
    onto_name=$(basename $onto .owl)
    out_dir=experiments/inf-dist/
    echo $out_dir
    mkdir -p $out_dir
    if ! [ -e $out_dir/$onto_name.txt ]
    then
        if ! systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.InfDistribution \
            $onto >$out_dir/$onto_name.txt 2>&1
        then
            rm $out_dir/$onto_name.txt
        fi
    fi
}

for onto in $ontos
do
    run-experiment $onto
done
