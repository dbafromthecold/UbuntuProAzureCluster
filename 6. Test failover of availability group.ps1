##############################################################################
#
# Test failing over the availability group
#
###############################################################################



# view cluster status
sudo crm status



# check availability group constraints
sudo crm resource constraints ms-ag1


# test moving the availability group
sudo crm resource move ms-ag1 ap-server-02



# view status
sudo crm status



# view constraints
sudo crm resource constraints ms-ag1



# deleting location constraints
sudo crm configure delete cli-prefer-ms-ag1



# view cluster status
sudo crm status
