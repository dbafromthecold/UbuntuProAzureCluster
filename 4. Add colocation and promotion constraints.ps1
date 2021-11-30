##############################################################################
#
# Add colocation and promotion constraints to pacemaker cluster
#
###############################################################################



# add colocation constraints to ensure listener and availability run on the same node
sudo crm configure colocation ag-with-listener INFINITY: virtualip-group ms-ag1:Master



# add order of promotion to ensure availability group comes online before listener
sudo crm configure order ag-before-listener Mandatory: ms-ag1:promote virtualip-group:start



# list  constraints
sudo crm configure show ag-with-listener
sudo crm configure show ag-before-listener



# view cluster
sudo crm status