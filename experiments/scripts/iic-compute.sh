
#!/bin/bash
# Given the repaired ontologies compute the iic.

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

for onto in $1/*
do
    for run in $onto/*
    do
        echo $run
        if ! [ -e $run/eval.txt ]
        then
            if ! systemd-run --scope -p MemoryMax=10G --user \
                java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                --reasoner=$REASONER $run/repair-*.owl --iic-pairs >$run/eval.txt 2>&1
            then
                if ! systemd-run --scope -p MemoryMax=10G --user \
                    java -cp target/shaded-ontologyutils-0.0.1.jar -Xms9G www.ontologyutils.apps.EvaluateRepairs \
                    --reasoner=hermit $run/repair-*.owl --iic-pairs >$run/eval.txt 2>&1
                then
                    echo "failed for $run"
                    rm $run/eval.txt
                fi
            fi
        fi
    done
done
