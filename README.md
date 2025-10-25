# WarehousePg tutorial

This tutoriam amis to explain in a practical way how to build a WarehousePg
clluster.

---

## About the lab environment

This tutorial is based on [AlmaLinux](https://almalinux.org) 9.  
But everyone is free to use any other Linux distribution based on RedHat.

| **Role**                                            | **hostname** | **IP address** |
|-----------------------------------------------------|--------------|----------------|
| Compiler (temp)                                     | compiler     | 192.168.56.99  |
| Master / coordinator                                | masterdb-01  | 192.168.56.10  |
| Standby coordinator (initially out of the cluster)  | masterdb-02  | 192.168.56.20  |
| Segment host 1                                      | sdw0         | 192.168.56.70  |
| Segment host 2                                      | sdw1         | 192.168.56.71  |
| Segment host 3                                      | sdw2         | 192.168.56.72  |
| Segment host 4 (initially out of the cluster)       | sdw3         | 192.168.56.73  |

--- 

[**Preparation**](00-preparition.md)   
[**Compilation**](01-compilation.md)  
[**A simple cluster configuration**](02-simple_cluster.md)  
[**Add a new segment node to the cluster**](03-add_new_segment.md)  



