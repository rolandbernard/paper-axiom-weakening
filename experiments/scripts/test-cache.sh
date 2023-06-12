#!/bin/bash
# Given the ontologies as input, test the cache effectiveness for each of them.

# GROUP_SIZES="1 5 10 20 50 100"
GROUP_SIZES="1 5 10 20"
TESTS_TO_RUN=100
# REASONER=fact++

ontos=$@

for REASONER in fact++ hermit jfact openllet
do

function run-experiment() {
    onto=$1
    size=$2
    onto_name=$(basename $onto .owl)
    out_dir=experiments/cache/$onto_name/
    echo $out_dir/$REASONER-$size
    mkdir -p $out_dir
    if ! [ -e $out_dir/$REASONER-$size.txt ]
    then
        if ! systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.BenchCache \
            --reasoner=$REASONER --preset=bernard2023 $onto -n $TESTS_TO_RUN -s $size >$out_dir/$REASONER-$size.txt 2>&1
        then
            rm $out_dir/$REASONER-$size.txt
        fi
    fi
    if ! [ -e $out_dir/$REASONER-$size-basic.txt ]
    then
        if ! systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.BenchCache \
            --reasoner=$REASONER --preset=bernard2023 --basic-cache $onto -n $TESTS_TO_RUN -s $size >$out_dir/$REASONER-$size-basic.txt 2>&1
        then
            rm $out_dir/$REASONER-$size-basic.txt
        fi
    fi
    if ! [ -e $out_dir/$REASONER-$size-uncached.txt ]
    then
        if ! systemd-run --scope -p MemoryMax=10G --user \
            java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.BenchCache \
            --reasoner=$REASONER --preset=bernard2023 --uncached $onto -n $TESTS_TO_RUN -s $size >$out_dir/$REASONER-$size-uncached.txt 2>&1
        then
            rm $out_dir/$REASONER-$size-uncached.txt
        fi
    fi
}

for size in $GROUP_SIZES
do
    for onto in $ontos
    do
        run-experiment $onto $size
    done
done

done
