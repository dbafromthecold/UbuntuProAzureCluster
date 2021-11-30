##############################################################################
#
# Create availability group
#
###############################################################################



# create availability group extended event
ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);
GO



# confirm extended event
mssql-cli -S ap-server-01 -U sa -P Testing1122 -Q "SELECT [name], [create_time] FROM [sys].[dm_xe_sessions];"



# create certificate on primary server
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PASSWORD';
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
BACKUP CERTIFICATE dbm_certificate
   TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
   WITH PRIVATE KEY (
           FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
           ENCRYPTION BY PASSWORD = 'PASSWORD'
       );



# copy certificate to other nodes
sudo su
cd /var/opt/mssql/data
sudo scp dbm_certificate.* dbafromthecold@ap-server-02:~
sudo scp dbm_certificate.* dbafromthecold@ap-server-03:~
exit



# copy the cert to /var/opt/mssql/data and set permissions
sudo su
cp /home/dbafromthecold/dbm_certificate.* /var/opt/mssql/data/
chown mssql:mssql /var/opt/mssql/data/dbm_certificate.*
exit



# create the certificate on the other servers
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PASSWORD';
CREATE CERTIFICATE dbm_certificate
    FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
    WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
    DECRYPTION BY PASSWORD = 'PASSWORD'
            );



# confim certificate on secondary servers
mssql-cli -S ap-server-02 -U sa -P Testing1122 -Q "SELECT [name] FROM [sys].[certificates]"



# create the availability endpoints on all three servers
CREATE ENDPOINT [Hadr_endpoint]
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
	    ROLE = ALL,
	    AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
		);
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;



# confirm endpoints
mssql-cli -S ap-server-01 -U sa -P Testing1122 -Q "SELECT [name], [type_desc], [state_desc] FROM [sys].[tcp_endpoints];"



# create pacemaker login
USE [master]
GO
CREATE LOGIN [pacemakerLogin] with PASSWORD= N'PASSWORD';
ALTER SERVER ROLE [sysadmin] ADD MEMBER [pacemakerLogin];
GO



# confirm login
mssql-cli -S ap-server-01 -U sa -P Testing1122 -Q "SELECT [name], [type_desc] FROM [sys].[server_principals];"



# create password file on all three servers
echo 'pacemakerLogin' >> ~/pacemaker-passwd
echo 'PASSWORD' >> ~/pacemaker-passwd
sudo mv ~/pacemaker-passwd /var/opt/mssql/secrets/passwd
sudo chown root:root /var/opt/mssql/secrets/passwd
sudo chmod 400 /var/opt/mssql/secrets/passwd



# Create the availability group with 3 nodes to provide quorum
# Standard edition allows for 2 nodes plus a configuration only SQL Express instance
CREATE AVAILABILITY GROUP [ag1]
     WITH (CLUSTER_TYPE = EXTERNAL)
     FOR REPLICA ON
         N'ap-server-01' 
 	      	WITH (
  	       ENDPOINT_URL = N'tcp://ap-server-01:5022',
  	       AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = EXTERNAL,
  	       SEEDING_MODE = AUTOMATIC
  	       ),
         N'ap-server-02' 
  	    WITH ( 
  	       ENDPOINT_URL = N'tcp://ap-server-02:5022', 
  	       AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = EXTERNAL,
  	       SEEDING_MODE = AUTOMATIC
  	       ),
  	   N'ap-server-03'
         WITH( 
  	      ENDPOINT_URL = N'tcp://ap-server-03:5022', 
  	      AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
  	      FAILOVER_MODE = EXTERNAL,
  	      SEEDING_MODE = AUTOMATIC
  	      );
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;
GO



# join secondaries to the availability group
ALTER AVAILABILITY GROUP [ag1] JOIN WITH (CLUSTER_TYPE = EXTERNAL);
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;



# grant pacemaker permissions to ag
GRANT ALTER, CONTROL, VIEW DEFINITION ON AVAILABILITY GROUP::ag1 TO [pacemakerLogin];
GRANT VIEW SERVER STATE TO [pacemakerLogin];
GO



# confirm availability group
mssql-cli -S ap-server-01 -U sa -P Testing1122 -Q "SELECT [group_name], [node_name] FROM [sys].[dm_hadr_availability_replica_cluster_nodes];"



# create the AG resource
sudo crm configure primitive ag1_cluster \
   ocf:mssql:ag \
   params ag_name="ag1" \
   meta failure-timeout=60s \
   op start timeout=60s \
   op stop timeout=60s \
   op promote timeout=60s \
   op demote timeout=10s \
   op monitor timeout=60s interval=10s \
   op monitor timeout=60s on-fail=demote  interval=11s role="Master" \
   op monitor timeout=60s interval=12s role="Slave" \
   op notify timeout=60s

sudo crm configure ms ms-ag1 ag1_cluster \
   meta master-max="1" master-node-max="1" clone-max="3" \
   clone-node-max="1" notify="true"



# view availability group resource
sudo crm resource status ms-ag1



# add database to availability group
USE [master];
GO

CREATE DATABASE [testdatabase1];
GO

BACKUP DATABASE [testdatabase1] TO DISK = N'/var/opt/mssql/data/testdatabase1.bak';
BACKUP LOG [testdatabase1] TO DISK = N'/var/opt/mssql/data/testdatabase1.trn';
GO

ALTER AVAILABILITY GROUP [ag1] ADD DATABASE [testdatabase1];
GO



# create listener resource
sudo crm configure primitive virtualip \
   ocf:heartbeat:IPaddr2 \
   params ip=192.168.0.10



# view listener resource
sudo crm resource status virtualip



# go and create the load balancer in Azure
# https://docs.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-public-cli?tabs=option-1-create-load-balancer-standard



# Load Balancer requirement will be removed in the future 
# Allow deployment via multiple subnets
# https://techcommunity.microsoft.com/t5/azure-sql-blog/simplify-azure-sql-virtual-machines-ha-and-dr-configuration-by/ba-p/2882897



# view load balancer frontend Ip
az network lb list --resource-group apdemo --query "[].frontendIpConfigurations[].privateIpAddress"



# create resource to enable load balancer probe port
sudo crm configure primitive azure-load-balancer azure-lb params port=59999



# view load balancer resource
sudo crm resource status azure-load-balancer



# create group that contains virtual ip and load balancer
sudo crm configure group virtualip-group azure-load-balancer virtualip



# view group
sudo crm resource status virtualip-group



# view cluster status
sudo crm status