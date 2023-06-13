#!/bin/bash
# Run another repair using removal.

REASONER=fact++

for onto in $1/*
do
    for run in $onto/*
    do
        echo $run
        if ! [ -e $run/repair-remove.owl ]
        then
            if ! timeout 5m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairRemoval \
                --reasoner=$REASONER $run/inconsistent.owl -v -o $run/repair-remove.owl >$run/repair-remove.log 2>&1
            then
                echo "failed for $run"
                rm -f $run/repair-remove.owl $run/repair-remove.log
            fi
        fi
    done
done
