# Ubuntu Pro Azure Cluster

Code to create a pacemaker cluster running on Ubuntu Pro 20.04 to deploy a SQL availability group.

Blog post running through these steps is here: - <br>
https://dbafromthecold.com/2021/12/01/building-a-pacemaker-cluster-to-deploy-a-sql-server-availability-group-in-azure/

Pre-requisities: -
- azure cli installed
- azure account
- mssql-cli installed (optional)

Steps performed are: -

1. Create VMs in Azure
2. Install and configure pacemaker cluster
3. Create the availability group
4. Add colocation and promotion constraints
5. Configure fencing resource on pacemaker cluster
6. Test failover of availability group
