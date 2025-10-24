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