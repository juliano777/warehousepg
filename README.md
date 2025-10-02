# WarehousePg tutorial (Podman)


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



Network creation:
```bash
podman network create net_whpg
```

Environment variables regarding servers / containers:
```bash
CMPCT='compiler'  # Compiler container
MSTRDB='masterdb'  # Master (coordinator)
WHPGCLSTR="${MSTRDB} sdw1 sdw2 sdw3 sdw4"
ALLSRV="${CMPCT} ${WHPGCLSTR}"
```

Initial tasks for all containers:
```bash
for i in ${ALLSRV}; do
    # Container creation
    echo "--- ${i} ----------------------------------------------------------"
    podman container run -itd \
        --cap-add=NET_RAW  \
        --name ${i} \
        --hostname ${i}.edb \
        -p 5432 -p 22 \
        --network net_whpg almalinux:10

    # Copy scripts directory into the container
    podman container cp scripts ${i}:/tmp/

    # Make all scripts executable
    podman container exec -it ${i} sh -c 'chmod +x /tmp/scripts/*'

    # Perform all common tasks
    podman container exec -it ${i} sh -c '/tmp/scripts/00_common.sh'

done
```

Conpilation:
```bash
podman container exec -it ${CMPCT} /tmp/scripts/01_compilation.sh
```

WarehoousePG tarball installation on nodes:
```bash
for i in ${WHPGCLSTR}; do
    # Copy compiled WarehousePg tarball
    podman container cp compiler:/tmp/whpg.tar.xz ${i}:/tmp/

    # Exectute script to install dependencies and install the tarball content
    podman container exec -it ${i} sh -c '/tmp/scripts/02_nodes.sh'
done
```

SSH:
```bash
for i in ${WHPGCLSTR}; do
    # Copy compiled WarehousePg tarball
    podman container exec -itu gpadmin masterdb sh -c 'cat ~/.ssh/id_rsa.pub' | \
        podman container exec -iu gpadmin ${i} \
            sh -c 'cat >> ~/.ssh/authorized_keys'

    # 
    podman container exec -u gpadmin masterdb \
        sh -c "ssh -o StrictHostKeyChecking=no ${i}"

done
```


Master:
```bash
podman container exec -itu gpadmin masterdb \
    sh -c '/tmp/scripts/03_masterdb.sh'
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

-->



