##############################################################################
#
# Install and configure fencing on cluster
#
###############################################################################



# register a new application in Azure Active Directory and create a secret
1.Go to Azure Active Directory in the portal and make a note of the Tenant ID.
2.Click "App Registrations" on the left hand side menu and then click "New Registration"
3.Enter a Name and then select "Accounts in this organization directory only"
4.Select Application Type Web, enter  http://localhost as a sign-on URL then click "Register"
5.Click "Certificates and secrets" on the left hand side menu, then click "New client secret"
6.Enter a description and select an expiry period
7.Make a note of the value of the secret, it is used as the password below and the secret ID, it is used as the username below.
8. Click "Overview" and make a note of the Application ID. It is used as the login below



# create custom role
az role definition create --role-definition fence-agent-role.json
az role definition list --name "Linux Fence Agent Role-clus-server-01-fence-agent"



# assign role to the VMs in the cluster
1. For each of the VMs in the cluster, click "Access Control (IAM)" left hand side menu.
2. Click Add a role assignment (use the classic experience).
3. Select the role created above.
4. In the Select list, enter the name of the application created earlier.



# create STONITH resource using values from above and your subscription ID
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



# check cluster status
sudo crm status