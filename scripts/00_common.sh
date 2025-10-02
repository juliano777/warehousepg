#!/bin/bash

# Python ---------------------------------------------------------------------
# Set Python version
export PYTHON_VERSON='3.12'

# Python binary
export PYTHON="/usr/bin/python${PYTHON_VERSON}"

# Profile script
cat << EOF > /etc/profile.d/python.sh 
# Python environment variables
export PYTHON_VERSON='${PYTHON_VERSON}'

# Python binary
export PYTHON='/usr/bin/python${PYTHON_VERSON}'

EOF

# Update alternatives
update-alternatives --install /usr/bin/python3 python3 ${PYTHON} 1
update-alternatives --install /usr/bin/python3 python ${PYTHON} 1
update-alternatives --set python3 ${PYTHON}
update-alternatives --set python ${PYTHON}

# Packages -------------------------------------------------------------------

# Disable SSL repositories
echo 'sslverify=False' >> /etc/dnf/dnf.conf

# EPEL repository
dnf install -y epel-release

# Update the system
dnf update -y

# Install some packages
dnf install -y neovim bash-completion procps-ng util-linux sudo openssh-server

# Clear downloaded packages
dnf clean all

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
su - gpadmin -c "ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa"

# WarehousePg variables
cat << EOF > ~gpadmin/.whpg_vars
# WarehousePg Home (installation directory)
WHPG_HOME='/usr/local/whpg'

# Library directories
export LD_LIBRARY_PATH="\${WHPG_HOME}/lib:\${LD_LIBRARY_PATH}"

# Manuals directories
export MANPATH="\${WHPG_HOME}/man:\${MANPATH}"

# Master directory
export MASTER_DIRECTORY='/var/local/whpg/data/master'

# Data directory
DATA_DIRECTORY="/var/local/whpg/data/sdw1 /var/local/whpg/data/sdw2 \
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
echo "source /usr/local/whpg/greenplum_path.sh" >> ~gpadmin/.bash_profile
echo "source ~/.whpg_vars" >> ~gpadmin/.bash_profile

# Set ownership
chown -R gpadmin: ~gpadmin

# Configure kernel settings so the system is optimized for WarehousePG -------
# sys.sh

# OpenSSH server
ssh-keygen -A  # generating new host keys
/usr/sbin/sshd  # Start SSH service
