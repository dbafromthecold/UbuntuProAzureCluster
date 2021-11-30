##############################################################################
#
# Install and configure fencing on cluster
#
###############################################################################



# What we're going to do now is configure fencing on the cluster. Fencing is the isolation of a failed node in a cluster
# which is performed by a STONITH resource. STONITH stands for, Shoot the other node in the head, a bit melodramtic maybe but, 
# that exactly what it does. It'll restart the failed node, allowing to go down, reset, come back up and join the cluster, hopefully
# bringing the cluster into a healthy state



# register a new application in Azure Active Directory - linuxcluster-app
# create custom role
az role definition create --role-definition fence-agent-role.json
az role definition list --name "Linux Fence Agent Role-clus-server-01-fence-agent"
# assign role to the VMs in the cluster



# create STONITH resource
sudo crm configure primitive fence-vm stonith:fence_azure_arm \
params \
action=reboot \
resourceGroup="apdemo" \
username="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
login="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
passwd="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
tenantId="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
subscriptionId="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
pcmk_reboot_timeout=900 \
power_timeout=60 \
op monitor \
interval=3600 \
timeout=120



# set STONITH properties
sudo crm configure property cluster-recheck-interval=2min
sudo crm configure property start-failure-is-fatal=true
sudo crm configure property stonith-timeout=900
sudo crm configure property concurrent-fencing=true
sudo crm configure property stonith-enabled=true



# confirm STONITH device
sudo crm configure show fence-vm



# check cluster status
sudo crm status