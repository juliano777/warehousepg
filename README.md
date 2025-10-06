# WarehousePg tutorial (Podman)

## About the lab environment

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

HHTPS
```bash
git clone https://github.com/juliano777/warehousepg.git && cd warehousepg/
```

Environment variables regarding servers / servers:
```bash
 CMPLR='192.168.56.99'  # Compiler machine
 MSTRDB='192.168.56.70'  # Master (coordinator)
 SEGNODES='192.168.56.71 192.168.56.72 192.168.56.73 192.168.56.74'
 WHPGCLSTR="${MSTRDB} ${SEGNODES}"
 ALLSRV="${CMPLR} ${WHPGCLSTR}"
```

Copy local public SSH key to each server (user `tux`):
```bash
for i in ${ALLSRV}; do
    ssh-copy-id tux@${i}
done
```

Initial tasks for all servers:
```bash
for i in ${ALLSRV}; do
    # Copy scripts directory into the server
    scp -r scripts tux@${i}:/tmp/

    # Make all scripts executable
    ssh tux@${i} sh -c 'chmod +x /tmp/scripts/*'

    # Perform all common tasks
    ssh tux@${i} sh -c '/tmp/scripts/00_common.sh'

done
```

Conpilation:
```bash
ssh tux@${CMPLR} /tmp/scripts/01_compilation.sh
```

WarehoousePG tarball installation on nodes:
```bash
for i in ${WHPGCLSTR}; do
    # Copy compiled WarehousePg tarball
     compiler:/tmp/whpg.tar.xz ${i}:/tmp/

    # Exectute script to install dependencies and install the tarball content
    ssh tux@${i} sh -c '/tmp/scripts/02_nodes.sh'
done
```

SSH:
```bash
for i in ${WHPGCLSTR}; do
    # Add Master SSH key (gpadmin user) to segment nodes
    podman server exec -itu gpadmin masterdb sh -c 'cat ~/.ssh/id_rsa.pub' | \
        podman server exec -iu gpadmin ${i} \
            sh -c 'cat >> ~/.ssh/authorized_keys'

    # Allow hosts automatically
    podman server exec -u gpadmin masterdb \
        sh -c "ssh -o StrictHostKeyChecking=no ${i}"

done
```

Cluster nodes:
```bash
for i in ${WHPGCLSTR}; do
    podman server exec -u gpadmin ${i} \
        sh -c 'source ~/.whpg_vars && mkdir -p ${DATA_DIRECTORY}'

    if [ ${i} == ${MSTRDB} ]; then
        podman server exec -u gpadmin ${i} sh -c "source ~/.whpg_vars && \
            mkdir -p  \${MASTER_DIRECTORY}"
    fi
done
```

Master:
```bash
podman server exec -itu gpadmin masterdb \
    sh -c 'source ~/.whpg_vars && /tmp/scripts/03_masterdb.sh'
```



MasterDB node; a script reset:
```bash
cat << EOF > reset.sh && chmod +x reset.sh
#!/bin/bash

rm -fr /var/local/whpg/{data,gpAdminLogs} && mkdir -p /var/local/whpg/data/sdw{1,2,3}
mkdir /var/local/whpg/data/master
ssh sdw1 'rm -fr /var/local/whpg/data && mkdir -p /var/local/whpg/data/sdw{1,2,3}'
ssh sdw2 'rm -fr /var/local/whpg/data && mkdir -p /var/local/whpg/data/sdw{1,2,3}'
ssh sdw3 'rm -fr /var/local/whpg/data && mkdir -p /var/local/whpg/data/sdw{1,2,3}'
gpinitsystem -c ~/gpinitsystem_config -h ~/hostfile_gpinitsystem -a

EOF
```


        
<!--

```bash
# /etc/hosts
cat << EOF >> /etc/hosts

#
master
sdw1
sdw2
sdw3

EOF
```

gpinitsystem -c ~/gpinitsystem_config -h ~/hostfile_gpinitsystem -a


rm -fr /var/local/whpg/data && \
ssh sdw1 'rm -fr /var/local/whpg/data' && \
ssh sdw3 'rm -fr /var/local/whpg/data' && \
ssh sdw2 'rm -fr /var/local/whpg/data' && \
ssh sdw4 'rm -fr /var/local/whpg/data' && \
rm -fr gpA*


-->



