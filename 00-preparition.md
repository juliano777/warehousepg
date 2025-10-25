# Preparion

Get to work!  
First, let's do some small tasks to define our environment.

## Github repository clone
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

 # Segment node IPs
 SEGNODES='192.168.56.71 192.168.56.72 192.168.56.73'

 # Cluster members
 WHPGCLSTR="${MSTRDB} ${SEGNODES}"

 # Segment node names
 SEGS='sdw1 sdw2 sdw3'

 # Coordinator / master node
 MSTRDB_NAME='masterdb'

 # Cluster members
 MEMBERS="${MSTRDB_NAME} ${SEGS}"
 
 # Domain 
 DOMAIN='my.domain'
```