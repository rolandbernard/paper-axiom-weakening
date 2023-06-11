#!/bin/bash
# Given the ontologies as input, make each of them inconsistent and the repair the again using
# maximal consistent sets and iterated weakening. Save the results of all repairs in subfolders.

RUN=$(date --iso-8601=seconds)
REPAIRS_PER_RUN=100
REASONER=fact++

function repair-mcs() {
    if timeout 10m \
        systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairMcs \
            --compute=sample -v --reasoner=$REASONER --limit $REPAIRS_PER_RUN -o $2 $1 >$3 2>&1
    then
        return 0
    else
        return 1
    fi
}

function repair-weakening() {
    if timeout 30m \
        systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairWeakening \
            --preset=bernard2023 -v --reasoner=$REASONER --limit $REPAIRS_PER_RUN -o $2 $1 >$3 2>&1
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
    mkdir -p $out_dir/{mcs,weakening}
    mkdir -p experiments/repairs/$RUN/.failed/
    if make-inconsistent $onto $out_dir/inconsistent.owl $out_dir/make-inconsistent.log
    then
        classify-ontology $out_dir/inconsistent.owl $out_dir/ontology-info.txt
        if repair-mcs $out_dir/inconsistent.owl $out_dir/mcs/repair.owl $out_dir/repair-mcs.log
        then
            if repair-weakening $out_dir/inconsistent.owl $out_dir/weakening/repair.owl $out_dir/repair-weakening.log
            then
                success=1
            fi
        fi
    fi
    if [ $success == 0 ]
    then
        mv $out_dir experiments/repairs/$RUN/.failed/
        return 1
    else
        return 0
    fi
}

todo=$@
while [ "$todo" ]
do
    redo=$todo
    todo=
    for onto in $redo
    do
        if ! run-experiment $onto
        then
            todo="$todo $onto"
        fi
    done
done
