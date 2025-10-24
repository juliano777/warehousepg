# Compilation

This will be the starting point for this tutorial, which will be the
compilation the source code so that it can be installed on the members of
the WarehousePg cluster.

```bash
 # Copy public SSH key automatically accepting the host key
 ssh-copy-id -o StrictHostKeyChecking=no tux@${i} 2> /dev/null

 # Copy scripts directory into the server
 rsync --delete-before -r scripts tux@${i}:/tmp/

 # Make all scripts executable
 ssh tux@${i} 'chmod +x /tmp/scripts/*'

 # Perform all common tasks
 ssh -t tux@${i} 'sudo /tmp/scripts/01-common.sh' 
```

Compilation:
```bash
# Compilation script
ssh -t tux@${CMPLR} 'sudo /tmp/scripts/03-compilation.sh'

# Copy the generated tarball to local /tmp
scp tux@${CMPLR}:/tmp/whpg.tar.xz /tmp/
```

> **Important!!!**   
> Here it is quite possible that manual interventions will be necessary for
> now.  
> Variable settings for compilation.

Compilation:
```bash
# Compilation script
ssh -t tux@${CMPLR} 'sudo init 0'
```

This machine had only one role: to compile the source code.  
So we can turn it off.
