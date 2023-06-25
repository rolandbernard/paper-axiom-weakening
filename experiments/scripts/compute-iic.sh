#!/bin/bash
# Given the repaired ontologies compute the iic.

REASONER=fact++
REASONER_FALLBACK=hermit

for onto in $1/*
do
    for run in $onto/*
    do
        echo $run
        if ! [ -e $run/eval.txt ]
        then
            if ! timeout 20m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                --reasoner=$REASONER $run/repair-*.owl --iic-pairs >$run/eval.txt 2>&1
            then
                if ! timeout 20m \
                    systemd-run --scope -p MemoryMax=10G --user \
                    java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                    --reasoner=$REASONER_FALLBACK $run/repair-*.owl --iic-pairs >$run/eval.txt 2>&1
                then
                    echo "failed for $run"
                    rm $run/eval.txt
                fi
            fi
        fi
    done
done
