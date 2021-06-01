#!/usr/bin/env python3

import numpy as np
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], low_memory=False, parse_dates=['timestamp'])

# Due to how lab.js works, 'error trials' get a separate additional row 
# that has to be merged in with the next one to get the total time for that trial.

# The way I wrote the task, the "corrected" next row has correct = NA.

# So we need to combine those 'failed' trials in the sender with the next 
# 'successful' which will be an 'after keypress' one. There's only ever two 
# that need to be collapsed.

# I (Dan) am currently too dumb to figure out a vector/functional way to do 
# this op. So now we iterate!

# Finding blocks w/ incorrect trials:
# df[(df['correct'] == False)].groupby(by=['ppt', 'session', 'block_number']).count()

df = df.sort_values(['ppt', 'observation', 'timestamp'])
incorrect = df[(df['correct'] == False)]

for i, row in incorrect.iterrows():
    df.loc[i, 'duration'] += df.loc[i+1, 'duration']

# Now that the 'correct' row has the duration of 'incorrect' + 'corrected', we 
# can drop the extra 'after keypress' rows where correct is NA.
df = df.dropna(subset=['correct'])

# Note that this leaves the rows where someone pressed the wrong button as 'correct' = False
# which the analysis to calculate D doesn't use, but might be important for someone someday?

df.to_csv(sys.argv[2])
