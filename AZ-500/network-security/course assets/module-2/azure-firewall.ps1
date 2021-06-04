$resourceGroupName = "rg-demo"
$region = "westeurope"
$vmSubnetAddressRange = "10.0.2.0/24"

# Create a virtual network with a firewall subnet and a VM workload subnet
# Remember the firewall subnet must be called 'AzureFirewallSubnet'
$firewallSubnet = New-AzVirtualNetworkSubnetConfig
            -Name "AzureFirewallSubnet"
            -AddressPrefix 10.0.1.0/26

$vmSubnet = New-AzVirtualNetworkSubnetConfig
            -Name "vmWorkloadSubnet"
            -AddressPrefix $vmSubnetAddressRange

$vnet = New-AzVirtualNetwork -Name "vnet1"
            -ResourceGroupName $resourceGroupName
            -Location $region
            -AddressPrefix 10.0.0.0/16
            -Subnet $firewallSubnet, $vmSubnet

# Create a public IP address for the firewall
$firewallPublicIp = New-AzPublicIpAddress
            -Name "firewall-public-ip"
            -ResourceGroupName $resourceGroupName
            -Location $region
            -AllocationMethod Static
            -Sku Standard

# Deploy an azure firewall to the virtual network
$firewall = New-AzFirewall -Name "firewall-demo"
            -ResourceGroupName $resourceGroupName
            -Location $region
            -VirtualNetwork $vnet
            -PublicIpAddress $firewallPublicIp

#Get the firewall private IP address
$firewallPrivateIP = $firewall.IpConfigurations.privateipaddress

# Create a route table with BGP route propagation disabled
$routeTable = New-AzRouteTable 
        -Name "firewall-route-table"
        -ResourceGroupName $resourceGroupName
        -location $region
        -DisableBgpRoutePropagation

# Create a default route in the route table so traffic is routed to the firewall
Add-AzRouteConfig
        -Name "firewall-default-route"
        -RouteTable $routeTable 
        -AddressPrefix 0.0.0.0/0 
        -NextHopType "VirtualAppliance"
        -NextHopIpAddress $firewallPrivateIP
| Set-AzRouteTable

#Associate the route table to the VM subnet
Set-AzVirtualNetworkSubnetConfig
        -VirtualNetwork $vnet
        -Name "vmWorkloadSubnet"
        -AddressPrefix $vmSubnetAddressRange
        -RouteTable $routeTable | Set-AzVirtualNetwork




# Configure an application rule to allow outbound access to www.pluralsight.com
$appRule1 = New-AzFirewallApplicationRule
        -Name "Allow-Pluralsight"
        -SourceAddress $vmSubnetAddressRange
        -Protocol http, https
        -TargetFqdn "www.pluralsight.com"

# Create an application rule collection 
$appRuleCollection1 = New-AzFirewallApplicationRuleCollection
        -Name "appRuleCollection1"
        -Priority 100
        -ActionType Allow
        -Rule $appRule1

# Add the application rule collection to the firewall
$firewall.ApplicationRuleCollections.Add($appRuleCollection1)

# Update the firewall
Set-AzFirewall -AzureFirewall $firewall


# Configure a network rule to allow outbound access to 2 external DNS servers (209.244.0.3,209.244.0.4)
$networkRule1 = New-AzFirewallNetworkRule
        -Name "Allow-DNS"
        -Protocol UDP
        -SourceAddress $vmSubnetAddressRange
        -DestinationAddress 209.244.0.3,209.244.0.4
        -DestinationPort 53

# Create a network rule collection 
$networkRuleCollection1 = New-AzFirewallNetworkRuleCollection
        -Name "networkRuleCollection1"
        -Priority 100
        -Rule $networkRule1
        -ActionType "Allow"

# Add the network rule collection to the firewall
$firewall.NetworkRuleCollections.Add($networkRuleCollection1)

# Update the firewall
Set-AzFirewall -AzureFirewall $firewall


# Configure an NAT rule to open port 30000 on the firewall to allow inbound RDP traffic from any source to a VM at 10.0.2.1
# This rule would be used to obscure the fact that port 3389 is open on the VM
$natRule1 = New-AzFirewallNatRule
        -Name "allowRdp"
        -Protocol "TCP"
        -SourceAddress "*"
        -DestinationAddress $firewallPublicIp
        -DestinationPort "30000"
        -TranslatedAddress "10.0.2.1"
        -TranslatedPort "3389"

# Create a nat rule collection 
$natRuleCollection1 = New-AzFirewallNatRuleCollection
        -Name "natRuleCollection1"
        -Priority 100
        -Rule $natRule1

# Add the nat rule collection to the firewall
$firewall.NatRuleCollections.Add($natRuleCollection1)

# Update the firewall
Set-AzFirewall -AzureFirewall $firewall