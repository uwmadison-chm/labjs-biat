#!/usr/bin/env python3

import numpy as np
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], low_memory=False, parse_dates=['timestamp'])

# Due to how lab.js works, 'error trials' get a separate additional row 
# that has to be merged in with the next one to get the total time for that trial.

# So we need to collapse those 'failed' trials in the sender into the next 
# 'successful' which will be an 'after keypress' one. There's only ever two 
# that need to be collapsed.

# I (Dan) am currently too dumb to figure out a vector/functional way to do 
# this op. So now we iterate!

df = df.sort_values(['ppt', 'observation', 'timestamp'])
incorrect = df[(df['correct'] == False)]

for i, row in incorrect.iterrows():
    df.loc[i+1, 'duration'] += row.duration 

# Now that the 'correct' row has the duration of 'incorrect' + 'correct', we 
# can drop the incorrect rows.
df = df[(df['correct'] == True)]

df.to_csv(sys.argv[2])
