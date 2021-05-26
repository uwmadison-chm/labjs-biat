DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

set_study chad

python3 duplicate_session_cleanup.py \
    /study/chad/raw-data/behavioral/biat/data.csv \
    /study/chad/intermediate_data/behavioral/biat/data_deduped.csv

python3 merge_failure_trials.py \
    /study/chad/intermediate_data/behavioral/biat/data_deduped.csv
    /study/chad/intermediate_data/behavioral/biat/data_merged.csv

/apps/x86_64_sci7/current/bin/singularity run \
    --bind /study/chad:/study/chad \
    --app Rscript r.sif biat_scoring.R \
    /study/chad/intermediate_data/behavioral/biat/data_merged.csv \
    /study/chad/intermediate_data/behavioral/biat/data_scored.csv


