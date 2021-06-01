#!/usr/bin/env python3

import logging
import numpy as np
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], low_memory=False, parse_dates=['timestamp'])

# First just drop some columns we don't need: a bunch of extraneous lab.js 
# nonsense and stuff that is used for display
columns_to_drop = ['url1', 'seed', 'random', 'block_total', 'sender_type', 
        'sender_id', 'first_kind_is_picture', 'has_two']
df = df.drop(columns_to_drop, axis=1)

# Lab.js stores data for every screen.
# Drop the intro screens and other stuff we don't need like ISI
# and the top-level Loop components, we really only care about
# when stimuli are on the screen.
drop_senders = [
  "Start (block total in Scripts)",
  "Mammals and Birds",
  "Democrats and Republicans",
  "Intro",
  "Block Sequence",
  "Trials (Stimuli selection in Scripts)",
  "Trial Sequence",
  "ISI"
  ]

df = df[ \
    ~(df['sender'].isin(drop_senders)) & 
    # Skipped screens were never displayed, ignore
    ~(df['ended_on'] == "skipped") &
    # We don't use practice block
    ~(df['practice'] == True) &
    # Ignore garbage pilot data
    (df['ppt'] < 9000)
    ]

# Sort by ppt, then observation (lab.js session), then time, just makes more 
# sense than whatever random order is coming out of sqlite and the R converter
df = df.sort_values(['ppt', 'observation', 'timestamp'])

# Group by ppt and session and find those with more than one lab.js observation
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


na_durations = df['duration'].isnull().sum()

if na_durations > 0:
    # Some durations are NA, warn and force them to 0, likely button mashing?
    # na_durations.time_show is NA
    logging.warning(f"Got {na_durations} NaN durations, setting to zero")

    df['duration'] = df['duration'].fillna(0)

df.to_csv(sys.argv[2])
