# WarehousePg tutorial

This tutoriam amis to explain in a practical way how to build a WarehousePg
clluster.

## About the lab environment

This tutorial is based on [Rocky Linux](https://rockylinux.org) 10.  
But everyone is free to use any other Linux distribution based on RedHat.

| **Role**                                      | **hostname** | **IP address** |
|-----------------------------------------------|--------------|----------------|
| Compiler (temp)                               | compiler     | 192.168.56.99  |
| Master (coordinator)                          | masterdb     | 192.168.56.70  |
| Segment host 1                                | sdw1         | 192.168.56.71  |
| Segment host 2                                | sdw2         | 192.168.56.72  |
| Segment host 3                                | sdw3         | 192.168.56.73  |
| Segment host 4 (initially out of the cluster) | sdw4         | 192.168.56.74  |


## Clone this repository

First of all clone this repository and then go to the directory.

For example:

SSH:
```bash
git clone git@github.com:juliano777/warehousepg.git && cd warehousepg/
``` 

or 

HTTPS
```bash
git clone https://github.com/juliano777/warehousepg.git && cd warehousepg/
```

## General procedures for all machines

Environment variables regarding servers:
```bash
 # Compiler machine
 CMPLR='192.168.56.99'

 # Master (coordinator)
 MSTRDB='192.168.56.70'

 # Segment Node IPs
 SEGNODES='192.168.56.71 192.168.56.72 192.168.56.73 192.168.56.74'

 # Cluster members
 WHPGCLSTR="${MSTRDB} ${SEGNODES}"

 # All servers
 ALLSRV="${CMPLR} ${WHPGCLSTR}"
```

Copy local public SSH key to each server (user `tux`):
```bash
 for i in ${ALLSRV}; do
    echo "===== [${i}] ==========================================="

    # Copy public SSH key automatically accepting the host key
    ssh-copy-id -o StrictHostKeyChecking=no tux@${i} 2> /dev/null
done
```

System configuration for all servers:
```bash
 for i in ${ALLSRV}; do
    echo "===== [${i}] ==========================================="
    # Copy scripts directory into the server
    scp -r scripts tux@${i}:/tmp/

    # Make all scripts executable
    ssh tux@${i} 'chmod +x /tmp/scripts/*'

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/00_sys.sh'
done
```

Wait for all server to restart...

Initial tasks for all servers:
```bash
 for i in ${ALLSRV}; do
    echo "===== [${i}] ==========================================="

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/01_common.sh'
done
```

## Source code compilation

Conpilation:
```bash
# Compilation script
ssh -t tux@${CMPLR} 'sudo /tmp/scripts/02_compilation.sh'

# Copy the generated tarball to local /tmp
scp tux@${CMPLR}:/tmp/whpg.tar.xz /tmp/
```

> **Important!!!**   
> Here it is quite possible that manual interventions will be necessary for
> now.  
> Variable settings for compilation.

## WarehousePg "installation"

WarehoousePG tarball installation on nodes:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Copy compiled WarehousePg tarball
    scp /tmp/whpg.tar.xz tux@${i}:/tmp/

    # Exectute script to install dependencies and install the tarball content
    ssh -t tux@${i} 'sudo /tmp/scripts/03_nodes.sh'
done
```

Authorize the public key of the coordinator's `gpadmin`user on each node in
the cluster:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Copy local SSH pub key to node
    scp ~/.ssh/id_rsa.pub tux@${i}:/tmp/

    # Add the copied key as an authorized key for gpadmin user
    CMD='cat /tmp/id_rsa.pub | sudo tee -a ~gpadmin/.ssh/authorized_keys'

    #  and remove the file
    CMD="${CMD} && rm -f /tmp/id_rsa.pub"

    # Ensure the ownership for gpadmin user
    CMD="${CMD} && chown -R gpadmin: ~gpadmin"

    # Execute the commands
    ssh -t tux@${i} "${CMD}"
done
```

## Building the cluster

From the coordinator node, gpadmin user, add each host member as a known host:
```bash
 MEMBERS='masterdb sdw1 sdw2 sdw3 sdw4'
 DOMAIN='my.domain'

 # BY IP address
 for i in ${WHPGCLSTR}; do
    CMD="ssh-copy-id -o StrictHostKeyChecking=no ${i} 2> /dev/null"
    ssh gpadmin@${i} "${CMD}"
done

 # By hostname and hostname with domain
 for i in ${MEMBERS}; do
    # Short hostname
    SHORT="ssh-copy-id -o StrictHostKeyChecking=no ${i} 2> /dev/null"
    
    # Long hostname (with domain)
    LONG="ssh-copy-id -o StrictHostKeyChecking=no ${i}.${DOMAIN} 2> /dev/null"

    # Concatenate the both commands into a unique variable
    CMD="${SHORT} && ${LONG}"

    # Execute the command
    ssh gpadmin@${MSTRDB} "${CMD}"
done 
```

Creating directories for the coordinator and segments:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Coomand to create the directories
    CMD='source ~/.whpg_vars && mkdir -p ${DATA_DIRECTORY}'
    CMD_MSTR="${CMD} \${MASTER_DIRECTORY}"
    
    if [ ${i} == ${MSTRDB} ]; then
        # Command to create directories in the coordinator
        CMD="${CMD_MSTR}"
    fi

    # Command execution via SSH
    ssh -t tux@${i} "sudo su - gpadmin -c '${CMD}'"

done
```

Building the cluster on coordinator node:
```bash
# Execute the script that will build the cluster
ssh gpadmin@${MSTRDB} '/tmp/scripts/04_masterdb.sh'
```

## Extra

In case of error it's possible to use reset script and start over.  
On coordinator node, user `gpadmin`:
```bash
cat << EOF > reset.sh && chmod +x reset.sh
#!/bin/bash

# Coordinator node -----------------------------------------------------------

# Remove directories
rm -fr /var/local/whpg/{data,gpAdminLogs}

# Recreating the directories
mkdir -p /var/local/whpg/data/sdw{1,2,3} /var/local/whpg/data/master

# Segment nodes --------------------------------------------------------------
for i in 'sdw1 sdw2 sdw3'; do
    # Command to remove the directories
    DIRRM='rm -fr /var/local/whpg/data'

    # Command to recreate the directories
    DIRMK='mkdir -p /var/local/whpg/data/sdw{1,2,3}'

    # Command to be executed merging both
    CMD="\${DIRRM} && \${DIRMK}"

    # Command execution
    ssh \${i} "\${CMD}"
done

# Cluster creation
gpinitsystem -c ~/gpinitsystem_config -h ~/hostfile_gpinitsystem -a
EOF
```
