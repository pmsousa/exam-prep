$resourceGroupName = 'rg-demo'
$region = 'westeurope'
$vmSubnetName = 'subnet-vm'
$vmSubnetIpRange = "10.0.2.0/24"
$bastionSubnetIpRange = "10.0.1.0/24"

# Create a virtual network with a Vm workload subnet and a bastion subnet 
# Remember, the bastion subnet must be called 'AzureBastionSubnet'
$bastionSubnet = New-AzVirtualNetworkSubnetConfig
            -Name "AzureBastionSubnet"
            -AddressPrefix $bastionSubnetIpRange
$vmSubnet = New-AzVirtualNetworkSubnetConfig
            -Name "subnet-vm"
            -AddressPrefix $vmSubnetIpRange
$vnet = New-AzVirtualNetwork
            -ResourceGroupName $resourceGroupName
            -Name 'vnet1'
            -AddressPrefix '10.0.0.0/16'
            -Location $region
            -Subnet $bastionSubnet, $vmSubnet


# Create public IP address for the bastion
$publicip = New-AzPublicIpAddress
            -ResourceGroupName $resourceGroupName
            -name "bastionPublicIP"
            -location $region
            -AllocationMethod Static
            -Sku Standard

# Create an Azure Bastion
$bastion = New-AzBastion
            -ResourceGroupName $resourceGroupName
            -Name "BastionDemo"
            -PublicIpAddress $publicip
            -VirtualNetwork $vnet


# Create an NSG rule to allow inbound HTTPS traffic to the bastion subnet from the Internet
$bastionRule1 = Add-AzNetworkSecurityRuleConfig
            -Name "allowHttpsFromInternet"
            -Description "Allow HTTPS from Internet"
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 110
            -SourceAddressPrefix "Internet"
            -SourcePortRange *
            -DestinationAddressPrefix *
            -DestinationPortRange 443

# Create an NSG rule to allow inbound HTTPS traffic to the bastion subnet from the Gateway Manager
$bastionRule2 = New-AzNetworkSecurityRuleConfig
            -Name "allowHttpsFromGatewayManager"
            -Description "Allow HTTPS from Gateway Manager"
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 120
            -SourceAddressPrefix "GatewayManager"
            -SourcePortRange 3389
            -DestinationAddressPrefix *
            -DestinationPortRange 3389

# Create an NSG rule to allow outbound RDP and SSH traffic to the virtual machines subnet from the bastion subnet
$bastionRule3 = New-AzNetworkSecurityRuleConfig
            -Name "allowSshRdpOutbound"
            -Description "Allow SSH and RDP to VM subnet"
            -Access Allow
            -Protocol Tcp
            -Direction Outbound
            -Priority 130
            -SourceAddressPrefix $bastionSubnetIpRange
            -SourcePortRange (22,3389)
            -DestinationAddressPrefix $vmSubnetIpRange
            -DestinationPortRange (22,3389)

# Create an NSG rule to allow outbound HTTPS traffic to Azure public endpoints for diagnostics etc from the bastion subnet
$bastionRule4 = New-AzNetworkSecurityRuleConfig
            -Name "allowHttpsToAzureCloud"
            -Description "Allow HTTPS to Azure Cloud"
            -Access Allow
            -Protocol Tcp
            -Direction Outbound
            -Priority 140
            -SourceAddressPrefix $bastionSubnetIpRange
            -SourcePortRange 443
            -DestinationAddressPrefix "AzureCloud"
            -DestinationPortRange 443

# Create an NSG with the specified rules
$bastionNsg = New-AzNetworkSecurityGroup
            -Name "bastion-nsg"
            -ResourceGroupName $resourceGroupName
            -Location  $region
            -SecurityRules $bastionRule1,$bastionRule2, $bastionRule3, $bastionRule4

# Associate the NSG with the bastion subnet
Set-AzVirtualNetworkSubnetConfig
            -VirtualNetwork $vnet
            -Name "AzureBastionSubnet"
            -AddressPrefix $bastionSubnetIpRange
            -NetworkSecurityGroup $bastionNsg


# Create an NSG rule to allow inbound RDP and SSH traffic to the target virtual machines subnet from the bastion subnet

$vmRule1 = New-AzNetworkSecurityRuleConfig
            -Name "allowSshRdpFromBastion"
            -Description "Allow SSH and RDP from the bastion subnet"
            -Access Allow
            -Protocol Tcp
            -Direction Inbound
            -Priority 110
            -SourceAddressPrefix $bastionSubnetIpRange
            -SourcePortRange (22,3389)
            -DestinationAddressPrefix $vmSubnetIpRange
            -DestinationPortRange (22,3389)

# Create an NSG with the specified rule
$vmNsg = New-AzNetworkSecurityGroup
            -Name "vm-nsg"
            -ResourceGroupName $resourceGroupName
            -Location  $region
            -SecurityRules $vmRule1

# Associate the NSG with the VM subnet
Set-AzVirtualNetworkSubnetConfig
            -VirtualNetwork $vnet
            -Name $vmSubnetName
            -AddressPrefix $vmSubnetIpRange
            -NetworkSecurityGroup $vmNsg