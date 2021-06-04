$resourceGroupName = "rg-demo"
$region = "westeurope"
$vnetName = "vnet1"

# Create a virtual network
$vnet = New-AzVirtualNetwork
        -ResourceGroupName $resourceGroupName
        -Location $region
        -Name $vnetName
        -AddressPrefix 10.0.0.0/16

# Create a DDoS protection plan
$ddosProtectionPlan = New-AzDdosProtectionPlan
        -ResourceGroupName $resourceGroupName
        -Name "DemoPlan1"
        -Location $region


# Apply the plan to the virtual network
$vnet.DdosProtectionPlan = New-Object Microsoft.Azure.Commands.Network.Models.PSResourceId
$vnet.DdosProtectionPlan.Id = $ddosProtectionPlan.Id
$vnet.EnableDdosProtection = $true
$vnet | Set-AzVirtualNetwork