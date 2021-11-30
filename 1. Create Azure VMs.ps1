##############################################################################
#
# Create 3 Azure VMs running Ubuntu Pro 20.04 and 1 jumpbox running Windows 11
#
###############################################################################



# login to azure
az login



# check VM images available
az vm image list --all --offer "sql2019-ubuntupro2004"
az vm image list --all --offer "windows-11"



# set resource group name
$resourceGroup = "apdemo"



# set password for access to VMs
$Password = "XXXXXXXXXXXXX"



# create resource group
az group create `
--name $resourceGroup `
--location eastus



# create availability set for VMs
az vm availability-set create `
--resource-group $resourceGroup `
--name $resourceGroup-as1 `
--platform-fault-domain-count 2 `
--platform-update-domain-count 2



# create virtual network
az network vnet create `
--resource-group $resourceGroup `
--name $resourceGroup-vnet `
--address-prefix 192.168.0.0/16 `
--subnet-name  $resourceGroup-vnet-sub1 `
--subnet-prefix 192.168.0.0/24



# create VMs for cluster
$Servers=@("ap-server-01","ap-server-02","ap-server-03")

foreach($Server in $Servers){
    az vm create `
    --resource-group "$resourceGroup" `
    --name $server `
    --availability-set "$resourceGroup-as1" `
    --size "Standard_D4s_v3" `
    --image "MicrosoftSQLServer:sql2019-ubuntupro2004:sqldev_upro:15.0.211020" `
    --admin-username "dbafromthecold" `
    --admin-password $Password `
    --authentication-type password `
    --os-disk-size-gb 128 `
    --vnet-name "$resourceGroup-vnet" `
    --subnet "$resourceGroup-vnet-sub1" `
    --public-ip-address '""'
}



# create a public IP address for jump box
az network public-ip create `
--name "ap-jump-01-pip" `
--resource-group "$resourceGroup"



# create jump box running Windows 11
az vm create `
--resource-group "$resourceGroup" `
--name "ap-jump-01" `
--availability-set "$resourceGroup-as1" `
--size "Standard_D4s_v3" `
--image "MicrosoftWindowsDesktop:windows-11:win11-21h2-pro:22000.318.2111041236" `
--admin-username "dbafromthecold" `
--admin-password $Password `
--os-disk-size-gb 128 `
--vnet-name "$resourceGroup-vnet" `
--subnet "$resourceGroup-vnet-sub1" `
--public-ip-address "ap-jump-01-pip"



# list VMs
az vm list --resource-group apdemo -o tsv --query '[].[location, resourceGroup, name]'