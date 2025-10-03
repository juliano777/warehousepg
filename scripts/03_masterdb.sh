#!/bin/bash

# Read environment variables file
source ~/.whpg_vars

# Cluster initial configuration ----------------------------------------------

# Segment hosts file
cat << EOF > ~gpadmin/hostfile_gpinitsystem
sdw1
sdw2
sdw3
EOF

# Initialization configuration file for WarehousePG
cat << EOF > ~gpadmin/gpinitsystem_config
ARRAY_NAME='whcluster_acme'
DATABASE_NAME=${PGDATABASE}
COORDINATOR_HOSTNAME=`hostname -s`
PORT_BASE=60000
MASTER_ARRAY_HOST=0
COORDINATOR_PORT=${PGPORT}
SEG_PREFIX=gpseg
MASTER_DIRECTORY=${MASTER_DIRECTORY}
MACHINE_SEGMENTS=3
EOF

for i in ${DATA_DIRECTORY}; do
    echo "DATA_DIRECTORY='${i}'" >> ~gpadmin/gpinitsystem_config
done

# libxerces-c-3.2.so



