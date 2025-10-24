#!/bin/bash

# All arguments as segments
SEGS="${@}"

# DATA_DIRECTORY base
DATA_DIRECTORY='/var/local/whpg/data'

# Empty array
PATHS=()

# Loop to add elements (paths) to array
for i in ${SEGS}; do
    PATHS+=("${DATA_DIRECTORY}/${i}")
done

# DATA_DIRECTORY variable now as all paths
DATA_DIRECTORY="${PATHS[@]}"

# WarehousePg variables
cat << EOF > ~gpadmin/.whpg_vars
# WarehousePg Home (installation directory)
export GPHOME='/usr/local/whpg'

# WarehousePg bin directory
export WHPGBIN="\${GPHOME}/bin"

# Library directories
#export LD_LIBRARY_PATH="\${GPHOME}/lib:\${LD_LIBRARY_PATH}"

# Manuals directories
export MANPATH="\${GPHOME}/man:\${MANPATH}"

# Master directory
export MASTER_DIRECTORY='/var/local/whpg/data/master'

# Data directory
export DATA_DIRECTORY="${DATA_DIRECTORY}"

# Coordinator data directory
export COORDINATOR_DATA_DIRECTORY="\${MASTER_DIRECTORY}/gpseg-1"

# DB port
export PGPORT='5432'

# DB user
export PGUSER='gpadmin'

# Database
export PGDATABASE='gpadmin'

# PATH
export PATH="\${PATH}:\${WHPGBIN}"

# PYTHONPATH
export PYTHONPATH="\${GPHOME}/lib/python:\`/usr/local/bin/get_pythonpath\`"

# Unset variable
unset WHPGBIN
EOF

# New lines to profile script
CMD="grep -E '^source /usr/local/whpg/greenplum_path.sh' \
    ~gpadmin/.bash_profile &> /dev/null"

if ! (eval "${CMD}"); then
    echo "source /usr/local/whpg/greenplum_path.sh" >> ~gpadmin/.bash_profile
    echo "source ~/.whpg_vars" >> ~gpadmin/.bash_profile
fi

# Set ownership
chown -R gpadmin: ~gpadmin