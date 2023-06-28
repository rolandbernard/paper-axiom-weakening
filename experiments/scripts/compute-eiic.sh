#!/bin/bash
# Given the repaired ontologies compute the iic.

REASONER=fact++
REASONER_FALLBACK=hermit

for onto in $1/*
do
    for run in $onto/*
    do
        echo $run
        if ! [ -e $run/eeval.txt ]
        then
            if ! timeout 20m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/ontologyutils.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                --reasoner=$REASONER $run/repair-*.owl --iic-pairs --extended >$run/eeval.txt 2>&1
            then
                if ! timeout 20m \
                    systemd-run --scope -p MemoryMax=10G --user \
                    java -cp target/ontologyutils.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                    --reasoner=$REASONER_FALLBACK $run/repair-*.owl --iic-pairs --extended >$run/eeval.txt 2>&1
                then
                    echo "failed for $run"
                    rm $run/eeval.txt
                fi
            fi
        fi
    done
done
