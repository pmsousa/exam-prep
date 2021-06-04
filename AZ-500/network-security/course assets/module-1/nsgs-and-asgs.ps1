$resourceGroupName = 'rg-demo'
$region = 'westeurope'
$frontEndSubnetName = "subnet-frontend"
$backEndSubnetName = "subnet-backend"

# Create a virtual network with a front-end subnet and back-end subnet.
$frontEndSubnet = New-AzVirtualNetworkSubnetConfig
            -Name 'subnet-frontend'
            -AddressPrefix '10.0.1.0/24'
$backEndSubnet = New-AzVirtualNetworkSubnetConfig
            -Name 'subnet-backend'
            -AddressPrefix '10.0.2.0/24'
$vnet = New-AzVirtualNetwork
            -ResourceGroupName $resourceGroupName
            -Name 'MyVnet'
            -AddressPrefix '10.0.0.0/16'
            -Location $region
            -Subnet $frontEndSubnet, $backEndSubnet


# Create an NSG rule to allow HTTP traffic in from the Internet to the frontend subnet
$frontendRule1 = New-AzNetworkSecurityRuleConfig
            -Name 'Allow-HTTP-All'
            -Description 'Allow HTTP' `
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 100 
            -SourceAddressPrefix Internet
            -SourcePortRange *
            -DestinationAddressPrefix *
            -DestinationPortRange 80

# Create an NSG rule to allow RDP traffic from the Internet to the front-end subnet
$frontendRule2 = New-AzNetworkSecurityRuleConfig
            -Name 'Allow-RDP-All'
            -Description "Allow RDP"
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 200
            -SourceAddressPrefix Internet
            -SourcePortRange *
            -DestinationAddressPrefix *
            -DestinationPortRange 3389

# Create a network security group with the rules you just created
$nsgFrontend = New-AzNetworkSecurityGroup
            -ResourceGroupName $resourceGroupName
            -Location $region
            -Name 'nsg-frontend'
            -SecurityRules $frontendRule1,$frontendRule2

# Associate the frontend NSG to the frontend subnet.
Set-AzVirtualNetworkSubnetConfig
            -VirtualNetwork $vnet
            -Name $frontEndSubnetName
            -AddressPrefix '10.0.1.0/24'
            -NetworkSecurityGroup $nsgFrontend


# Create an application security group
$asg1 = New-AzApplicationSecurityGroup
            -ResourceGroupName $resourceGroupName
            -Name "asg1"
            -Location $region

# Create an NSG rule to allow SQL traffic from an application security group to the back-end subnet.
$backendRule1 = New-AzNetworkSecurityRuleConfig
            -Name 'Allow-SQL-From-ASG1'
            -Description "Allow SQL"
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 100
            -SourceApplicationSecurityGroup $asg1
            -SourcePortRange *
            -DestinationAddressPrefix *
            -DestinationPortRange 1433

# Create a network security group for the backend subnet
$nsgBackend = New-AzNetworkSecurityGroup
            -ResourceGroupName $resourceGroupName
            -Location $resourceGroupName
            -Name "nsg-backend"
            -SecurityRules $backendRule1

# Associate the backend NSG to the backend subnet
Set-AzVirtualNetworkSubnetConfig
            -VirtualNetwork $vnet
            -Name $backEndSubnetName
            -AddressPrefix '10.0.2.0/24'
            -NetworkSecurityGroup $nsgBackend

# Create an NSG rule to block all outbound traffic from the backend subnet to the Internet
$backendRule2 = New-AzNetworkSecurityRuleConfig
            -Name 'Deny-Internet-All'
            -Description "Deny Internet All"
            -Access Deny
            -Protocol Tcp
            -Direction Outbound
            -Priority 200
            -SourceAddressPrefix *
            -SourcePortRange *
            -DestinationAddressPrefix Internet
            -DestinationPortRange *

# Add an NSG rule to an existing NSG
$nsgBackend.SecurityRules.add($backendRule2)
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsgBackend