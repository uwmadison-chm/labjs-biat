# Brief IAT lab.js scoring

`run_script.sh` chains together some python and some R.

The Python gets everything situated from the weird trial format that the 
lab.js task output dumps.

The R implements the various filtering needed to calculate D from the Nosek 
Brief IAT paper, using dplyr and tidyr from tidyverse.

Order of execution looks like:

    python3 duplicate_session_cleanup.py input.csv deduped.csv
    python3 merge_failure_trials.py deduped.csv merged.csv
    Rscript biat_scoring.R merged.csv output.csv

