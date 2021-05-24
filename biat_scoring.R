#!/usr/bin/env Rscript

# NOTE: Run the python scripts on the data first, THEN run this on that output

require('tidyverse')

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]

# TODO: How to read args when doing devel.sh?
# Ugh. For now, just hardcode it
input <- "/study/chad/intermediate_data/behavioral/biat/data_cleaned.csv"
data <- read_csv(input, col_types = cols(
  # Remove a bunch of extraneous lab.js nonsense
  # and stuff that is used for display
  'url1'=col_skip(),
  'seed'=col_skip(),
  'random'=col_skip(),
  'block_total'=col_skip(),
  'sender_type'=col_skip(),
  'sender_id'=col_skip(),
  'first_kind_is_picture'=col_skip(),
  'has_two'=col_skip()
  )) %>%
  select(-starts_with('meta')) %>%
  select(-starts_with('help')) %>%
  select(-starts_with('stimuli')) %>%
  select(-starts_with('url'))

# Lab.js stores data for every screen.
# Drop the intro screens and other stuff we don't need like ISI
# and the top-level Loop components, we really only care about
# when stimuli are on the screen.
drop_senders <- c(
  "Start (block total in Scripts)",
  "Mammals and Birds",
  "Democrats and Republicans",
  "Intro",
  "Block Sequence",
  "Trials (Stimuli selection in Scripts)",
  "Trial Sequence",
  "ISI"
  )
data <- data %>%
  filter(!sender %in% drop_senders) %>%
  # Skipped screens were never displayed, ignore
  filter(!ended_on == "skipped") %>%
  # We don't use practice data
  filter(!practice) %>%
  # Ignore garbage pilot data
  filter(ppt < 9000) %>%
  # Sort by time
  arrange(timestamp)

tasks_obs <- data %>% group_by(ppt, session)

tasks <- data %>% group_by(ppt, session)

# TODO: maybe just clean this with pandas


# ANYWAY ignore that.
# For now, st group by lab.js observation
tasks <- data %>% group_by(ppt, session, observation)

"
Cleanup time, from Table 8 in Nosek, et. al 2014:

    Remove trials > 10000ms.
    Remove first four trials in each block.
    Retain error trials.
    Recode <400ms to 400ms and >2000ms to 2000ms.
    Remove tasks with >10% fast responses.
    Compute D separately for each pair of two consecutive blocks separately, then average those

Sounds easy enough...
"


blocks = tasks %>%
  group_by(block_number, .add = TRUE)

# TODO: count trials in each block, check for any that are not 20

# Remove first four trials in each block.
blocks <- blocks %>%
  slice(5:n())

# Remove trials > 10000ms.
blocks <- blocks %>%
  filter(duration < 10000)

# Recode <400ms to 400ms and >2000ms to 2000ms.
blocks <- blocks %>%
  mutate(duration = ifelse(duration > 2000, 2000, duration)) %>%
  mutate(duration = ifelse(duration < 400, 400, duration))

# Removing tasks with >10% responses <300ms happened in the python script


"""
OK, assuming we have the right data ready finally, for each ppt session we compute D twice.

We do this for blocks 2+3, and then blocks 4+5, and then average

- compute SD, the standard deviation of ALL latencies
- find M1, the mean of the latencies in condition 1.
- find M2, the mean of the latencies in condition 2.
- D = (M2 - M1)/SD
"""

# First, ungroup by block and group by blocks 2+3 and 4+5 instead

# TODO: condition is found from left1/left2 and correct_response

d_blocks <- blocks %>%
  ungroup() %>%
  mutate(calc_d_block = ifelse(block_number == 2 | block_number == 3, 1, 2)) %>%
  group_by(ppt, session, calc_d_block) %>%
  summarize(partial_d = (m2 - m1) / sd(duration)) %>%

d_blocks %>% 
  summarize(
    mean_duration = mean(duration),
    d = mean(partial_d),
    .groups = "keep"
  )

