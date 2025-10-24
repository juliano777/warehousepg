#!/bin/bash

# In case of error it's possible to use reset script and start over.  
# On coordinator node, user gpadmin

# Remove directories
rm -fr /var/local/whpg/{data,gpAdminLogs}

# Recreating the directories
mkdir -p /var/local/whpg/data/sdw{1,2,3} /var/local/whpg/data/master

# Segment nodes --------------------------------------------------------------
NODES='sdw1 sdw2 sdw3'
for i in \${NODES}; do
    # Command to remove the directories
    DIRRM='rm -fr /var/local/whpg/data'

    # Command to recreate the directories
    DIRMK='mkdir -p /var/local/whpg/data/sdw{1,2,3}'

    # Command to be executed merging both
    CMD="\${DIRRM} && \${DIRMK}"

    # Command execution
    ssh \${i} "\${CMD}"
done