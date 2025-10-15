#!/bin/bash

# Read environment variables file
source ~/.whpg_vars

# Cluster initial configuration ----------------------------------------------

SEG='sdw1 sdw2 sdw3'
DOMAIN='my.domain'

# Segment hosts file and host add key
for i in ${SEG}; do
    echo "${i}" >> ~gpadmin/hostfile_gpinitsystem
    ssh-copy-id -o StrictHostKeyChecking=no ${i} 2> /dev/null
    ssh-copy-id -o StrictHostKeyChecking=no ${i}.${DOMAIN} 2> /dev/null
done

# Initialization configuration file for WarehousePG
cat << EOF > ~gpadmin/gpinitsystem_config
ARRAY_NAME='whcluster_acme'
DATABASE_NAME='${PGDATABASE}'
COORDINATOR_HOSTNAME='`hostname -f`'
PORT_BASE='60000'
MASTER_ARRAY_HOST='0'
COORDINATOR_PORT=${PGPORT}
SEG_PREFIX='gpseg'
MASTER_DIRECTORY='${MASTER_DIRECTORY}'

# Coordinator data directory environment variable
export COORDINATOR_DATA_DIRECTORY="\${MASTER_DIRECTORY}/gpseg-1"
MACHINE_SEGMENTS='3'
EOF

# Add each element of DATA_DIRECTORY variable
for i in ${DATA_DIRECTORY}; do
    echo "DATA_DIRECTORY='${i}'" >> ~gpadmin/gpinitsystem_config
done

# Cluster creation
gpinitsystem -c ~/gpinitsystem_config -h ~/hostfile_gpinitsystem -a
