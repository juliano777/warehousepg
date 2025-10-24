#!/bin/bash

# Configure kernel settings so the system is optimized for WarehousePG -------
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

# Get RAM in kb
RAM_IN_KB=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`

# Get RAM in bytes
RAM_IN_BYTES=$(($RAM_IN_KB*1024))

# Setting kernel parameters based on RAM values
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

# Apply the kernel parameters
sysctl -p /etc/sysctl.d/10-whpg.conf

# Security limits
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
sed 's/SELINUX=enforcing/SELINUX=disabled/g' -i /etc/selinux/config
setenforce 0

# As root, edit /etc/sssd/sssd.conf and add this parameter:
# selinux_provider=none
echo 'selinux_provider=none' >> /etc/sssd/sssd.conf

# Deactivate or Configure Firewall Software
systemctl disable --now firewalld

# /etc/hosts    
cat << EOF > /etc/hosts

127.0.0.1	    localhost.localdomain   localhost

# WarehousePg cluster --------------------------------------------------------
192.168.56.10   masterdb-01.my.domain  masterdb01
192.168.56.20   masterdb-02.my.domain  masterdb02
192.168.56.70   sdw0.my.domain  sdw0
192.168.56.71   sdw1.my.domain  sdw1
192.168.56.72   sdw2.my.domain  sdw2
192.168.56.73   sdw3.my.domain  sdw3
EOF

# Reboot
init 6
