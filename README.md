# Brief-IAT Lab.js task

Implementation of the Brief-IAT in Lab.js based on these two papers:

https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0110938

https://pcl.stanford.edu/research/2015/iyengar-ajps-group-polarization.pdf

## Task

Currently only the political polarization Brief-IAT is fully implemented, in:

* `political-polarization-brief-iat.json`

## Scoring

`run_script.sh` chains together some python and some R.

The Python gets everything situated from the weird trial format that the 
lab.js task output dumps.

The R implements the various filtering needed to calculate D from the Nosek 
Brief IAT paper, using dplyr and tidyr from tidyverse.

Order of execution looks like:

    python3 duplicate_session_cleanup.py input.csv deduped.csv
    python3 merge_failure_trials.py deduped.csv merged.csv
    Rscript biat_scoring.R merged.csv output.csv

## TODO

- This could all be much more general, it's quite targeted at the political 
  polarization style right now.
- The R script should look at `condition` now that the task stores it.

