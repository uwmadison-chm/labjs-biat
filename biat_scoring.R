#!/usr/bin/env Rscript

# NOTE: Run the python scripts on the data first, THEN run this on that output
# See run_script.sh

require('tidyverse')

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]

# Drop some more columns while reading this in
data <- read_csv(input) %>%
  select(-starts_with('meta')) %>%
  select(-starts_with('help')) %>%
  select(-starts_with('stimuli')) %>%
  select(-starts_with('url'))

tasks <- data %>% group_by(observation)

# Cleanup time, from Table 8 in Nosek, et. al 2014:
# 
#     Remove trials > 10000ms.
#     Remove first four trials in each block.
#     Retain error trials.
#     Recode <400ms to 400ms and >2000ms to 2000ms.
#     Remove tasks with >10% fast responses.
#     Compute D separately for each pair of two consecutive blocks separately, then average those
# 
# Sounds easy enough...

# Removing entire tasks with >10% responses <300ms
button_mashers = tasks %>%
  summarize(mean = mean(duration, na.rm=TRUE)) %>%
  filter(mean < 300)

tasks = tasks %>%
  filter(!observation %in% button_mashers$observation)


# Now let's separate into blocks for further processing
blocks = tasks %>%
  group_by(block_number, .add = TRUE)

# Remove first four trials in each block, which are the 'warmup' word-only trials
blocks <- blocks %>%
  slice(5:n())

# Remove trials > 10000ms.
blocks <- blocks %>%
  filter(duration < 10000)

# Recode <400ms to 400ms and >2000ms to 2000ms.
blocks <- blocks %>%
  mutate(duration = ifelse(duration > 2000, 2000, duration)) %>%
  mutate(duration = ifelse(duration < 400, 400, duration))


# OK, assuming we have the right data ready now, for each ppt session we compute D twice.
# Each row here is now one IAT trial
# 
# We do this for blocks 2+3, and then blocks 4+5, and then average
# 
# - compute SD, the standard deviation of ALL latencies
# - find M1, the mean of the latencies in condition 1.
# - find M2, the mean of the latencies in condition 2.
# - D = (M2 - M1)/SD

d_blocks <- blocks %>%
  # Figure out which condition we're in
  # It sure would have been smart for me to make the labjs task store this in a separate field but oh well!
  mutate(condition = ifelse( (left1 == 'Democrat' & left2 == 'Good') | (right1 == 'Democrat' & right2 == 'Good'), 1, 2)) %>%

  # Add a mean duration per block, but we want it to be negative where condition = 1
  # (this is the ugly way I am doing M2 - M1)
  # TODO: maybe consider grouping on block and condition?
  mutate(m = mean(duration) * ifelse(condition == 1, -1, 1)) %>%
  
  # We want to calculate D for blocks 2+3 and blocks 4+5 (1 was practice, dropped)
  # So d_block is either 1 or 2
  mutate(d_block = ifelse(block_number == 2 | block_number == 3, 1, 2)) %>%

  # Regroup based on d_block
  group_by(observation, d_block) %>%

  # Add a standard deviation across each entire d_block 
  mutate(sd = sd(duration)) %>%

  # Now we can finally calculate D by adding the means of the durations from each condition.
  # We don't want to sum ALL m, we want to pick ONE from each condition... so we use min and max
  # because one is positive and one is negative. This trickery essentially gets us M2 - M1.
  summarize(ppt = first(ppt), session = first(session),
            partial_d = (min(m) + max(m)) / sd) %>%

  # Now we group ONLY by observation and get the mean of d from that partial_d above.
  # Keeping ppt and session for final output
  group_by(observation, ppt, session) %>%

  # Yay? D is the mean of the two partial calculations
  summarize(d = mean(partial_d), trials = n())


# Final massaging, drop observation and pivot by session
output_table <- d_blocks %>%
  ungroup() %>%
  select(-observation) %>% 
  pivot_wider(names_from = session, values_from = c(d, trials)) %>%
  arrange(ppt)

write_csv(output_table, output)
