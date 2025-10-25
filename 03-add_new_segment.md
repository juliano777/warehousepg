# Add a new node as a segment

Setting variables:
```bash
 # IP address (162.168.56.73)
 read -p 'Enter the IP of the new segment: ' IP
 
 # Host name (sdw3)
 read -p 'Enter the domain of the new segment: ' SEGNAME
 
 # Domain (my.domain)
 read -p 'Enter the domain of the new segment: ' DOMAIN
 
 # Long hostname = hostname + domain
 LONGNAME="${SEGNAME}.${DOMAIN}"

 # 
 SEGS="${SEGS} ${SEGNAME}"

 # 
 WHPGCLSTR="${WHPGCLSTR} ${IP}"
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

Update WarehousePg environment variables file:
```bash
 for i in ${WHPGCLSTR}; do
    echo "===== [${i}] ==========================================="

    # Perform all common tasks
    ssh -t tux@${i} 'sudo /tmp/scripts/02-whpg_vars.sh' ${SEGS}
done
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
 # By IP address
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

Creating the coordinator node configuration
```bash
 CMD="/tmp/scripts/05-coord_conf.sh -s '${SEGS}' -d '${DOMAIN}'"
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

 # Create segments directory
 CMD="mkdir -p ${DATA_DIRECTORY}"

 # Create segments directory on master
 ssh gpadmin@${MSTRDB} "${CMD}"

 # Directories creation on segments
 CMD="bash -l -c 'gpssh -f ~/hostfile_gpinitsystem \"${CMD}\"'"
 ssh gpadmin@${MSTRDB} "${CMD}"
```

The file that list the new hosts that will receive segments:
```bash
 # Create expand file
 CMD="echo \"${LONGNAME}\" > ~/gpexpand_input"
 CMD="${CMD} && gpexpand -i -s -f ~/gpexpand_input"
 CMD="bash -l -c '${CMD}'"
 ssh gpadmin@${MSTRDB} "${CMD}"
```