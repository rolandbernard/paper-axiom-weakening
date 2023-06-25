#!/bin/bash
# Run another repair using removal.

REASONER=fact++

for onto in $1/*
do
    for run in $onto/*
    do
        echo $run
        if ! [ -e $run/repair-mcs.owl ]
        then
            if ! timeout 1m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairMcs \
                --compute=some -v --reasoner=$REASONER $run/inconsistent.owl -o $run/repair-mcs.owl >$run/repair-mcs.log 2>&1
            then
                echo "failed for $run"
                rm -f $run/repair-mcs.owl $run/repair-mcs.log
            fi
        fi
        if ! [ -e $run/repair-weakening.owl ]
        then
            if ! timeout 5m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairWeakening \
                --preset=bernard2023 -v --reasoner=$REASONER $run/inconsistent.owl -o $run/repair-weakening.owl >$run/repair-weakening.log 2>&1
            then
                echo "failed for $run"
                rm -f $run/repair-weakening.owl $run/repair-weakening.log
            fi
        fi
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
        if ! [ -e $run/repair-enhance.owl ]
        then
            if ! timeout 5m \
                systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.RepairWeakening \
                --preset=bernard2023 --enhance-ref -v --reasoner=$REASONER $run/inconsistent.owl -o $run/repair-enhance.owl >$run/repair-enhance.log 2>&1
            then
                echo "failed for $run"
                rm -f $run/repair-enhance.owl $run/repair-enhance.log
            fi
        fi
    done
done
