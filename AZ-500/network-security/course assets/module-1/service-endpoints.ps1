# Add a service endpoint to allow access from a subnet to an Azure SQL server
$resourceGroupName = 'rg-demo';
$region            = 'westeurope';
$vnetName            = 'vnet1';
$subnetName          = 'subnet1';
$VNetAddressPrefix   = '10.1.0.0/16';
$SubnetAddressPrefix = '10.1.1.0/24';

# Create a SQL server
$sqlAdministratorCredentials = New-Object
      -TypeName System.Management.Automation.PSCredential
      -ArgumentList
        "serverAdmin",
        $(ConvertTo-SecureString
            -String "AdminPassword1!"
            -AsPlainText
            -Force
         );

$sqlServer = New-AzSqlServer
      -ResourceGroupName $resourceGroupName
      -ServerName "demo-server1"
      -Location $region
      -SqlAdministratorCredentials $sqlAdministratorCredentials;

# Define a subnet with a service endpoint for SQL servers
$subnet = New-AzVirtualNetworkSubnetConfig
      -Name $subnetName
      -AddressPrefix $subnetAddressPrefix
      -ServiceEndpoint "Microsoft.Sql";

# Create a virtual network with the subnet
$vnet = New-AzVirtualNetwork 
      -Name $vnetName
      -AddressPrefix $vnetAddressPrefix
      -Subnet $subnet
      -ResourceGroupName $resourceGroupName
      -Location $region;

#Add the subnet's Id as a rule, to allow traffic through your SQL server's firewall from the subnet.";
$firewallRule1 = New-AzSqlServerVirtualNetworkRule 
      -ResourceGroupName $resourceGroupName 
      -ServerName "demo-server1" 
      -VirtualNetworkRuleName "Allow-subnet" 
      -VirtualNetworkSubnetId $subnet.Id;