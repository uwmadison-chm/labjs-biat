#!/usr/bin/env python3

import numpy as np
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], low_memory=False, parse_dates=['timestamp'])

# Group by ppt and session and find those with more than one lab.js observation

# Due to how lab.js works, 'error trials' get a separate additional row 
# that has to be merged in with the next one to get the total time for that trial.

# So we need to collapse those 'failed' trials in the sender into the next 
# 'successful' which will be an 'after keypress' one. There's only ever two 
# that need to be collapsed.

counts = df.groupby(by=['ppt', 'session']).observation.nunique()

dupes = counts.where(counts > 1).dropna().index

def drop_observation(df, obs):
    return df[df['observation'] != obs]

for ppt, session in dupes:
    tasks = df[(df['ppt'] == ppt) & (df['session'] == session)]

    counts = tasks.groupby(by='observation').size()

    # Drop any partially completed tasks
    for obs, count in counts.iteritems():
        if count < 20:
            df = drop_observation(df, obs)
            tasks = drop_observation(tasks, obs)

    counts = tasks.groupby(by='observation').size()

    # If we still have more than one task for this participant...
    # pick the newest and delete the rest
    if len(counts) > 1:
        # TODO: there must be a prettier way to do this but I am pandas-dumb
        keep = tasks[tasks['timestamp'] == tasks['timestamp'].max()].iloc[0].observation
        for obs, _ in counts.iteritems():
            if obs != keep:
                df = drop_observation(df, obs)
                tasks = drop_observation(tasks, obs)

# TODO: Some durations are NA, figure out why?

df.to_csv(sys.argv[2])
