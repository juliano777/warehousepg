#!/bin/bash

# In case of error it's possible to use reset script and start over.  
# On coordinator node, user gpadmin

#
gpstop -a

# Remove directories
rm -fr /var/local/whpg/{data,gpAdminLogs}

# Segment names
SEGS=`cut -f1 -d. ~/hostfile_gpinitsystem | tr '\n' ' '`

# Base directory 
DIRBASE='/var/local/whpg/data'

# Recreating the directories -------------------------------------------------
# Segment directories variable
DIRSEGS=()
for i in ${SEGS}; do
    DIRSEGS+="${DIRBASE}/${i} "
done

# Master directory variable
DIRMASTER="${DIRBASE}/master"

# Common command to be executed on all nodes
CMD="mkdir -p ${DIRSEGS}"

# Local execution
eval "${CMD} ${DIRMASTER}"

gpssh -f ~/hostfile_gpinitsystem "rm -fr ${DIRBASE}"
gpssh -f ~/hostfile_gpinitsystem "${CMD}"
