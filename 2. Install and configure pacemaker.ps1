##############################################################################
#
# Install and configure pacemaker cluster
#
###############################################################################



# log into jump box and test SSH to SQL Servers
ssh ap-server-01
ssh ap-server-02
ssh ap-server-03



# confirm sql ha agent present on the servers
sudo apt-get install mssql-server-ha



# enable agent and enable availability groups
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true 
sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
sudo systemctl restart mssql-server



# confirm properties have been set
sudo /opt/mssql/bin/mssql-conf get sqlagent
sudo /opt/mssql/bin/mssql-conf get hadr



# set sa password for SQL instances
sudo systemctl stop mssql-server
sudo /opt/mssql/bin/mssql-conf set-sa-password
sudo systemctl start mssql-server



# confirm connecting to SQL instances
mssql-cli -S ap-server-01 -U sa -P Testing1122 -Q "SELECT @@VERSION AS [Version];"



# check status of firewall, if active add in rules (see MS docs)
sudo ufw status



# add record of other servers to /etc/hosts
sudo vim /etc/hosts

192.168.0.4 ap-server-01
192.168.0.5 ap-server-02
192.168.0.6 ap-server-03
192.168.0.10 ap-server-10

cat /etc/hosts



# install required packages
sudo apt-get install -y pacemaker pacemaker-cli-utils crmsh resource-agents fence-agents csync2 python3-azure



# create authentication key on primary server
sudo corosync-keygen
sudo ls /etc/corosync



# copy key generated to other nodes
sudo scp /etc/corosync/authkey dbafromthecold@ap-server-02:~
sudo scp /etc/corosync/authkey dbafromthecold@ap-server-03:~



# move auth from home directory to /etc/corosync on other nodes
sudo mv authkey /etc/corosync/authkey



# edit the /etc/corosync/corosync.conf file on the primary server
sudo vim /etc/corosync/corosync.conf
sudo cat /etc/corosync/corosync.conf



# copy corosync.conf to other nodes
sudo scp /etc/corosync/corosync.conf dbafromthecold@ap-server-02:~
sudo scp /etc/corosync/corosync.conf dbafromthecold@ap-server-03:~



# replace conf file on other nodes
sudo mv corosync.conf /etc/corosync/



# restart corosync
sudo systemctl restart pacemaker corosync



# validate cluster quorum
sudo corosync-quorumtool -ai



# add user to haclient group
sudo usermod -aG haclient dbafromthecold