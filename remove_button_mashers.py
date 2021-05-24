#!/usr/bin/env python3

import numpy as np
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], low_memory=False)

# Now remove entire tasks with >10% responses <300ms
# TODO: look for... people with 10% of trials <300ms somehow

df.to_csv(sys.argv[2])
