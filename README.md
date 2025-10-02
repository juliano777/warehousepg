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
# Compiler container
CMPCT='compiler'
MSTRDB='masterdb'
WHPGCLSTR="${MSTRDB} sdw1 sdw2 sdw3 sdw4"
ALLSRV="${CMPCT} ${WHPGCLSTR}"
```

Initial tasks for all containers:
```bash
for i in ${ALLSRV}; do
    # Container creation
    echo "--- ${i} ----------------------------------------------------------"
    podman container run -itd --name ${i} --hostname ${i}.edb -p 5432 \
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







```bash
for i in ${ALLSRV}; do
    # Container creation
    podman container run -itd --name ${i} --hostname ${i}.edb -p 5432 \
        --network net_whpg almalinux:10

    podman container cp compiler:/tmp/whpg.tar.xz ${i}:/tmp/

    podman container cp /tmp/00_script.sh ${i}:/tmp/
podman container exec -it ${i} chmod +x /tmp/00_script.sh

    podman container exec -it ${i} /tmp/00_script.sh

done
```


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





