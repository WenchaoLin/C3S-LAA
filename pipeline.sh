#!/bin/sh

# 1) cluster reads
python cluster.py

# 2) consensus calling
### The following job needs to be run separately
# qsub consensus_calling.sh	(this file will be generated by running "cluster.py")

# 3) assembly of consensus sequences
python consensus_assembly.py