# Ubuntu Pro Azure Cluster

Code to create a pacemaker cluster running on Ubuntu Pro 20.04 to deploy a SQL availability group

Pre-requisities: -
- azure cli installed
- azure account

Steps performed are: -

1. Create VMs in Azure
2. Install and configure pacemaker cluster
3. Create the availability group
4. Add colocation and promotion constraints
5. Configure fencing resource on pacemaker cluster
6. Test failover of availability group