#!/bin/bash
# Given the ontologies as input, make each of them inconsistent and the repair the again using
# maximal consistent sets and iterated weakening. Save the results of all repairs in subfolders.

REPAIRS_PER_RUN=50

function repair-mcs() {
    java -cp target/shaded-ontologyutils-0.0.1.jar -Xmx10G www.ontologyutils.apps.RepairMcs \
        --compute=sample --limit $REPAIRS_PER_RUN -o $2 $1 >$3 2>&1
}

function repair-weakening() {
    java -cp target/shaded-ontologyutils-0.0.1.jar -Xmx10G www.ontologyutils.apps.RepairWeakening \
        --preset=bernard2023 --limit $REPAIRS_PER_RUN -o $2 $1 >$3 2>&1
}

function make-inconsistent() {
    java -cp target/shaded-ontologyutils-0.0.1.jar -Xmx10G www.ontologyutils.apps.MakeInconsistent \
        --strict-sroiq -o $2 $1 >$3 2>&1
}

function classify-ontology() {
    java -cp target/shaded-ontologyutils-0.0.1.jar www.ontologyutils.apps.ClassifyOntology \
        $1 >$2 2>&1
}

function run-experiment() {
    run=$(date --iso-8601=seconds)
    onto_name=$(basename $1 .owl)
    out_dir=experiments/repairs/$onto_name/$run/

    mkdir -p $out_dir/{mcs,weakening}
    make-inconsistent $1 $out_dir/inconsistent.owl $out_dir/make-inconsistent.log
    classify-ontology $out_dir/inconsistent.owl $out_dir/ontology-info.txt

    repair-mcs $out_dir/inconsistent.owl $out_dir/mcs/repair.owl $out_dir/repair-mcs.log
    repair-weakening $out_dir/inconsistent.owl $out_dir/weakening/repair.owl $out_dir/repair-weakening.log
}

for onto in $@
do
    run-experiment $onto &
done

