# Simple cluster

Copy local public SSH key to each server (user `tux`):
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Copy public SSH key automatically accepting the host key
    ssh-copy-id -o StrictHostKeyChecking=no tux@${i} 2> /dev/null
done
```

System configuration for all servers:
```bash
 for i in ${WHPGCLSTR}; do
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
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/01-common.sh'
done
```

WarehousePg environment variables file:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/02-whpg_vars.sh' ${SEGS}
done
```

# WarehousePg "installation"

WarehoousePG tarball installation on nodes:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Copy compiled WarehousePg tarball
    scp /tmp/whpg.tar.xz tux@${i}:/tmp/

    # Exectute script to install dependencies and install the tarball content
    ssh -t tux@${i} 'sudo /tmp/scripts/04-nodes.sh'
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
 # By IP address
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
 CMD="bash -l -c /tmp/scripts/05-coord_conf.sh '${SEGS}' '${DOMAIN}'"
 ssh gpadmin@${MSTRDB} "${CMD}"
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