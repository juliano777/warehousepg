#!/bin/bash

# Update the system ----------------------------------------------------------

# EPEL repository
dnf install -y epel-release

# Update the system
dnf update -y

# Python ---------------------------------------------------------------------
# Set Python version
export PYTHON_VERSON='3.12'

# Install Python
dnf install -y python${PYTHON_VERSON}

# Python binary
export PYTHON="/usr/bin/python${PYTHON_VERSON}"

# Profile script
cat << EOF > /etc/profile.d/python.sh 
# Python environment variables
export PYTHON_VERSON='${PYTHON_VERSON}'

# Python binary
export PYTHON='/usr/bin/python${PYTHON_VERSON}'

EOF

# Update alternatives regarding Python
update-alternatives --install /usr/bin/python3 python3 ${PYTHON} 1
update-alternatives --install /usr/bin/python3 python ${PYTHON} 1
update-alternatives --set python3 ${PYTHON}
update-alternatives --set python ${PYTHON}

# Packages -------------------------------------------------------------------

# Package list to be installed
PKG="xerces-c neovim bash-completion procps-ng util-linux sudo \
openssh-clients openssh-server iproute rsync python3-psycopg2 \
python3-pyyaml python3-psutil python3-setuptools tree"

# Install some packages and clear downloaded packages
dnf install -y ${PKG} && dnf clean all

# gpadmin system user --------------------------------------------------------

# Group creation
groupadd -r gpadmin

# User creation
useradd \
    -s /bin/bash \
    -md /var/local/whpg \
    -k /etc/skel \
    -g gpadmin \
    -G wheel \
    -c 'Greenplum admin WarehousePG user' \
    -r gpadmin

# Generate SSH keys for gpadmin
if [ ! -f ~gpadmin/.ssh/id_rsa ]; then
    su - gpadmin -c "ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa";
fi

# WarehousePg variables
cat << EOF > ~gpadmin/.whpg_vars
# WarehousePg Home (installation directory)
export WHPG_HOME='/usr/local/whpg'

# Library directories
#export LD_LIBRARY_PATH="\${WHPG_HOME}/lib:\${LD_LIBRARY_PATH}"

# Manuals directories
export MANPATH="\${WHPG_HOME}/man:\${MANPATH}"

# Master directory
export MASTER_DIRECTORY='/var/local/whpg/data/master'

# Data directory
export DATA_DIRECTORY="/var/local/whpg/data/sdw1 /var/local/whpg/data/sdw2 \
/var/local/whpg/data/sdw3"

# DB port
export PGPORT=5432

# DB user
export PGUSER=gpadmin

# Database
export PGDATABASE=gpadmin

# Unset variables
unset WHPG_HOME PGBIN
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
