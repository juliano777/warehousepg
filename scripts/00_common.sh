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
dnf install -y neovim bash-completion procps-ng util-linux sudo

# Configure kernel settings so the system is optimized for WarehousePG -------
mkdir /etc/sysctl.d 2> /dev/null
touch /etc/sysctl.conf

tee -a /etc/sysctl.d/10-whpg.conf << EOF
kernel.msgmax = 65536
kernel.msgmnb = 65536
kernel.msgmni = 2048
kernel.sem = 500 2048000 200 8192
kernel.shmmni = 1024
kernel.core_uses_pid = 1
kernel.core_pattern=/var/core/core.%h.%t
kernel.sysrq = 1
net.core.netdev_max_backlog = 2000
net.core.rmem_max = 4194304
net.core.wmem_max = 4194304
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.tcp_rmem = 4096 4224000 16777216
net.ipv4.tcp_wmem = 4096 4224000 16777216
net.core.optmem_max = 4194304
net.core.somaxconn = 10000
net.ipv4.ip_forward = 0
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_tw_recycle = 0
net.core.default_qdisc = fq_codel
net.ipv4.tcp_mtu_probing = 0
net.ipv4.conf.all.arp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.ipfrag_high_thresh = 41943040
net.ipv4.ipfrag_low_thresh = 31457280
net.ipv4.ipfrag_time = 60
net.ipv4.ip_local_reserved_ports=65330
vm.overcommit_memory = 2
vm.overcommit_ratio = 95
vm.swappiness = 10
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.zone_reclaim_mode = 0
EOF

RAM_IN_KB=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
RAM_IN_BYTES=$(($RAM_IN_KB*1024))
echo "vm.min_free_kbytes = $(($RAM_IN_BYTES*3/100/1024))" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
echo "kernel.shmall = $(($RAM_IN_BYTES/2/4096))" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
echo "kernel.shmmax = $(($RAM_IN_BYTES/2))" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
if [ $RAM_IN_BYTES -le $((64*1024*1024*1024)) ]; then
    echo "vm.dirty_background_ratio = 3" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
    echo "vm.dirty_ratio = 10" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
else
    echo "vm.dirty_background_ratio = 0" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
    echo "vm.dirty_ratio = 0" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
    echo "vm.dirty_background_bytes = 1610612736 # 1.5GB" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
    echo "vm.dirty_bytes = 4294967296 # 4GB" | tee -a /etc/sysctl.d/10-whpg.conf > /dev/null
fi

sysctl -p /etc/sysctl.d/10-whpg.conf

tee -a /etc/security/limits.d/10-nproc.conf << EOF
* soft nofile 524288
* hard nofile 524288
* soft nproc 131072
* hard nproc 131072
* soft core unlimited
EOF

ulimit -n 65536 65536

# /etc/selinux/config file. As root, change the value of the SELINUX
# parameter in the config file as follows:
# SELINUX=disabled

# As root, edit /etc/sssd/sssd.conf and add this parameter:
# selinux_provider=none

# Deactivate or Configure Firewall Software
systemctl disable --now firewalld

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
su - tux -c "ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa"

# WarehousePg variables
cat << EOF > ~gpafmin/.whpg_vars
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
/var/local/whpg/data/sdw3'

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
echo "source /usr/local/whpg/greenplum_path.sh" >> ~gpafmin/.bash_profile
echo "source ~/.whpg_vars" >> ~gpafmin/.bash_profile
