# WarehousePg tutorial

This tutoriam amis to explain in a practical way how to build a WarehousePg
clluster.

---

# About the lab environment

This tutorial is based on [AlmaLinux](https://almalinux.org) 9.  
But everyone is free to use any other Linux distribution based on RedHat.

| **Role**                                      | **hostname** | **IP address** |
|-----------------------------------------------|--------------|----------------|
| Compiler (temp)                               | compiler     | 192.168.56.99  |
| Master (coordinator)                          | masterdb     | 192.168.56.70  |
| Segment host 1                                | sdw1         | 192.168.56.71  |
| Segment host 2                                | sdw2         | 192.168.56.72  |
| Segment host 3                                | sdw3         | 192.168.56.73  |
| Segment host 4 (initially out of the cluster) | sdw4         | 192.168.56.74  |


# Clone this repository

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

# General procedures for all machines

Environment variables regarding servers:
```bash
 # Compiler machine
 CMPLR='192.168.56.99'

 # Master (coordinator)
 MSTRDB='192.168.56.70'

 # Segment Node IPs
 SEGNODES='192.168.56.71 192.168.56.72 192.168.56.73'

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
    rsync --delete-before -r scripts tux@${i}:/tmp/

    # Make all scripts executable
    ssh tux@${i} 'chmod +x /tmp/scripts/*'

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/00-sys.sh'
done
```

Wait for all servers to restart...

Initial tasks for all servers:
```bash
 for i in ${ALLSRV}; do
    echo "===== [${i}] ==========================================="

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/01-common.sh'
done
```

# Source code compilation

Conpilation:
```bash
# Compilation script
ssh -t tux@${CMPLR} 'sudo /tmp/scripts/02-compilation.sh'

# Copy the generated tarball to local /tmp
scp tux@${CMPLR}:/tmp/whpg.tar.xz /tmp/
```

> **Important!!!**   
> Here it is quite possible that manual interventions will be necessary for
> now.  
> Variable settings for compilation.

# WarehousePg "installation"

WarehoousePG tarball installation on nodes:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Copy compiled WarehousePg tarball
    scp /tmp/whpg.tar.xz tux@${i}:/tmp/

    # Exectute script to install dependencies and install the tarball content
    ssh -t tux@${i} 'sudo /tmp/scripts/03-nodes.sh'
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
    CMD="${CMD} && sudo chown -R gpadmin: ~gpadmin"

    # Execute the commands
    ssh -t tux@${i} "${CMD}"

    # Copy gpadmin pub key from coordinator node
    if [ "${i}" == "${MSTRDB}" ]; then
        scp gpadmin@${MSTRDB}:~gpadmin/.ssh/id_rsa.pub \
            /tmp/master-gpadmin.pub
    fi

    # Add gpadmin coordinator key to current node
    CMD='cat >> ~/.ssh/authorized_keys'
    cat /tmp/master-gpadmin.pub | ssh gpadmin@${i} "${CMD}"
done

 # Remove the file
 rm -f /tmp/master-gpadmin.pub
```

# Building the cluster

From the coordinator node, `gpadmin `user, add each host member as a known
host:
```bash
 MEMBERS='masterdb sdw1 sdw2 sdw3'
 DOMAIN='my.domain'

 # BY IP address
 for i in ${WHPGCLSTR}; do
    CMD="ssh-copy-id -o StrictHostKeyChecking=no ${i} 2> /dev/null"
    ssh gpadmin@${MSTRDB} "${CMD}"
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

Creating the coordinator node configuration
```bash
ssh gpadmin@${MSTRDB} 'bash -l -c "/tmp/scripts/04-coord_conf.sh"'
```

Creating directories for the coordinator and segments:
```bash

 # Data directories variable   
 DATA_DIRECTORY="`ssh gpadmin@${MSTRDB} 'source ~/.whpg_vars && \
    echo ${DATA_DIRECTORY}'`"

 # Master directory variable
 MASTER_DIRECTORY="`ssh gpadmin@${MSTRDB} 'source ~/.whpg_vars && \
    echo ${MASTER_DIRECTORY}'`"

 # Create directories on segments
 CMD="mkdir -p ${DATA_DIRECTORY}"

 # Create directories on coordinator node
 CMD_COORD="${CMD} ${MASTER_DIRECTORY}"

 # Directories creation on segments
 CMD="bash -l -c 'gpssh -f ~/hostfile_gpinitsystem \"${CMD}\"'"
 ssh gpadmin@${MSTRDB} "${CMD}"

 # Directories creation on coordinator
 ssh gpadmin@${MSTRDB} "${CMD_COORD}"
```

Cluster creation:
```bash
 CMD='gpinitsystem -c ~/gpinitsystem_config -h ~/hostfile_gpinitsystem -a'
 CMD="bash -l -c '${CMD}'"

 ssh gpadmin@${MSTRDB} "${CMD}" 
```

# Add a new node as a segment

Setting variables:
```bash
 # IP address
 read -p 'Enter the IP of the new segment: ' IP
 
 # Host name
 read -p 'Enter the domain of the new segment: ' SEGNAME
 
 # Domain
 read -p 'Enter the domain of the new segment: ' DOMAIN
 
 # Long hostname = hostname + domain
 LONGNAME="${SEGNAME}.${DOMAIN}"
```


Copy local public SSH key to (user tux):
```bash
 ssh-copy-id -o StrictHostKeyChecking=no tux@${IP} 2> /dev/null
```
 
System configuration:
```bash
 # Copy scripts directory into the server
 rsync --delete-before -r scripts tux@${IP}:/tmp/

 # Make all scripts executable
 ssh tux@${IP} 'chmod +x /tmp/scripts/*'
 
 # Perform all common tasks
 ssh -t tux@${IP} 'sudo /tmp/scripts/00-sys.sh'
```

Wait for restart...

Initial tasks:
```bash
 ssh -t tux@${IP} 'sudo /tmp/scripts/01-common.sh'
```

WarehoousePG tarball installation:
```bash
 # Copy compiled WarehousePg tarball
 scp /tmp/whpg.tar.xz tux@${IP}:/tmp/

 # Exectute script to install dependencies and install the tarball content
 ssh -t tux@${IP} 'sudo /tmp/scripts/03-nodes.sh'
```

Authorize the public key of the coordinator's gpadminuser:
```bash
 # Copy local SSH pub key to node
 scp ~/.ssh/id_rsa.pub tux@${IP}:/tmp/
    
 # Add the copied key as an authorized key for gpadmin user
 CMD='cat /tmp/id_rsa.pub | sudo tee -a ~gpadmin/.ssh/authorized_keys'
 
 #  and remove the file
 CMD="${CMD} && rm -f /tmp/id_rsa.pub"
 
 # Ensure the ownership for gpadmin user
 CMD="${CMD} && sudo chown -R gpadmin: ~gpadmin"

 # Execute the commands
 ssh -t tux@${IP} "${CMD}"
 
 # Copy gpadmin pub key from coordinator node
 scp gpadmin@${MSTRDB}:~gpadmin/.ssh/id_rsa.pub \
            /tmp/master-gpadmin.pub

 # Add gpadmin coordinator key to current node
 CMD='cat >> ~/.ssh/authorized_keys'
 cat /tmp/master-gpadmin.pub | ssh gpadmin@${IP} "${CMD}"
 
 # Remove the file
 rm -f /tmp/master-gpadmin.pub
```

From the coordinator node, `gpadmin` user, add each host member as a known
host:
```bash
 # BY IP address
 CMD="ssh-copy-id -o StrictHostKeyChecking=no ${IP} 2> /dev/null"
 
 # By hostname and hostname with domain
 # Short hostname
 SHORT="ssh-copy-id -o StrictHostKeyChecking=no ${SEGNAME} 2> /dev/null"
    
 # Long hostname (with domain)
 LONG="ssh-copy-id -o StrictHostKeyChecking=no ${LONGNAME} 2> /dev/null"

 # Concatenate the all commands into a unique variable
 CMD="${SHORT} && ${LONG} && ${CMD}"
 
 # Execute the command
 ssh gpadmin@${MSTRDB} "${CMD}"
```
