$resourceGroupName = "rg-demo"
$region = "westeurope"
$onPremisesVpnDeviceIP = "23.99.221.164"

# Create a virtual network with a subnet
$gatewaySubnet = Add-AzVirtualNetworkSubnetConfig
          -Name "gatewaySubnet"
          -AddressPrefix 10.1.1.0/24

$subnet1 = Add-AzVirtualNetworkSubnetConfig
          -Name "subnet1"
          -AddressPrefix 10.1.2.0/24

$vnet = New-AzVirtualNetwork
          -ResourceGroupName $resourceGroupName
          -Location $region
          -Name "vnet1"
          -Subnet ($gatewaySubnet, $subnet1)
          -AddressPrefix 10.1.0.0/16

# Create a public IP address for the gateway
$gatewayPublicIP = New-AzPublicIpAddress
          -Name "gateway-demo-public-ip"
          -ResourceGroupName $resourceGroupName
          -Location $region
          -AllocationMethod Dynamic

# Create the gateway's IP address configuration
$gatewayIpConfig = New-AzVirtualNetworkGatewayIpConfig
          -Name "gateway-ipconfig"
          -SubnetId $gatewaySubnet.Id
          -PublicIpAddressId $gatewayPublicIP.Id

# Create a route-based VPN gateway
$vpnGateway = New-AzVirtualNetworkGateway
          -Name "gateway-demo"
          -ResourceGroupName $resourceGroupName
          -Location $region
          -IpConfigurations $gatewayIpConfig
          -GatewayType Vpn
          -VpnType RouteBased
          -GatewaySku VpnGw1

# Create a local network gateway for your on-premises VPN device ()
$localGateway = New-AzLocalNetworkGateway
            -Name "On-premises"
            -ResourceGroupName $resourceGroupName
            -Location $region
            -GatewayIpAddress $onPremisesVpnDeviceIP
            -AddressPrefix @('10.101.0.0/24','10.101.1.0/24')

# Create a site-to-site VPN connection
New-AzVirtualNetworkGatewayConnection
            -Name "Vnet-to-on-premises"
            -ResourceGroupName $resourceGroupName
            -Location $region
            -VirtualNetworkGateway1 $vpnGateway
            -LocalNetworkGateway2 $localGateway
            -ConnectionType IPsec
            -RoutingWeight 10
            -SharedKey 'SecretKey123'

# You would then need to configure your on-premises VPN device