#!/bin/bash
# Given the ontologies as input, make each of them inconsistent and the repair the again using
# maximal consistent sets and iterated weakening. Save the results of all repairs in subfolders.

RUN=$(date --iso-8601=seconds)
REPAIRS_PER_RUN=100
REASONER=fact++

function repair-mcs() {
    if timeout 1m \
        systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairMcs \
            --compute=some -v --reasoner=$REASONER -o $2 $1 >$3 2>&1
    then
        return 0
    else
        return 1
    fi
}

function repair-weakening() {
    if timeout 5m \
        systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairWeakening \
            --preset=bernard2023 -v --reasoner=$REASONER -o $2 $1 >$3 2>&1
    then
        return 0
    else
        return 1
    fi
}

function make-inconsistent() {
    if timeout 5m \
        systemd-run --scope -p MemoryMax=10G --user \
        java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.MakeInconsistent \
        --strict-sroiq --strict-simple-roles --simple-ria-weakening --strict-owl2 -v --reasoner=$REASONER -o $2 $1 >$3 2>&1
    then
        return 0
    else
        return 1
    fi
}

function classify-ontology() {
    systemd-run --scope -p MemoryMax=10G --user \
        java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.ClassifyOntology \
        $1 >$2 2>&1
}

function run-experiment() {
    onto=$1
    onto_name=$(basename $onto .owl)
    out_dir=experiments/repairs/$RUN/$onto_name/
    success=0
    iter=0
    mkdir -p $out_dir/.failed
    mkdir -p experiments/repairs/$RUN/.failed/
    while [ $success -lt $REPAIRS_PER_RUN -a $iter -lt $(expr 4 \* $success + 4) ]
    do
        ok=0
        out_dir_iter=$out_dir/$iter
        mkdir -p $out_dir_iter
        if make-inconsistent $onto $out_dir_iter/inconsistent.owl $out_dir_iter/make-inconsistent.log
        then
            classify-ontology $out_dir_iter/inconsistent.owl $out_dir_iter/ontology-info.txt
            if repair-mcs $out_dir_iter/inconsistent.owl $out_dir_iter/repair-mcs.owl $out_dir_iter/repair-mcs.log
            then
                if repair-weakening $out_dir_iter/inconsistent.owl $out_dir_iter/repair-weakening.owl $out_dir_iter/repair-weakening.log
                then
                    success=$(expr $success + 1)
                    ok=1
                fi
            fi
        fi
        if [ $ok == 0 ]
        then
            mv $out_dir_iter $out_dir/.failed
        fi
        iter=$(expr $iter + 1)
    done
    if [ $success -lt $REPAIRS_PER_RUN ]
    then
        mv $out_dir experiments/repairs/$RUN/.failed/
        return 1
    else
        return 0
    fi
}

for onto in $@
do
    run-experiment $onto
done
