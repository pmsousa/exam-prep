$resourceGroupName = "rg-demo"
$allowedIpAddress = "26.27.28.29"

# ----------------------
# Only allow traffic from a certain IP address to an Azure storage account
# ----------------------
$storageAccountName = "firewalls-demo"

#Set the default firewall action to deny so all traffic to the storage account is denied
Update-AzStorageAccountNetworkRuleSet
        -ResourceGroupName $resourceGroupName
        -Name $storageAccountName
        -DefaultAction Deny

# Add a rule to only allow traffic from the specified IP address
Add-AzStorageAccountNetworkRule
        -ResourceGroupName $resourceGroupName
        -AccountName $storageAccountName
        -IPAddressOrRange $allowedIpAddress

# ----------------------
# Only allow traffic from a certain IP address to an Azure key vault
# ----------------------
$vaultName = "kv-demo"

# Set the default action to deny so all traffic to the key vault is denied
Update-AzKeyVaultNetworkRuleSet
        -VaultName $vaultName
        -DefaultAction Deny

# Add an IP address range from which to allow traffic.
Add-AzKeyVaultNetworkRule
        -VaultName $vaultName
        -IpAddressRange $allowedIpAddress

# If the key vault should be accessible by any trusted Azure services, set bypass to AzureServices.
Update-AzKeyVaultNetworkRuleSet
        -VaultName $vaultName
        -Bypass AzureServices


# ----------------------
# Only allow traffic from a certain IP address to an Azure app service
# ----------------------
$appServiceName = "demo-webapp"

# Add a rule to only allow traffic from the specified IP address
Add-AzWebAppAccessRestrictionRule
        -ResourceGroupName $resourceGroupName
        -WebAppName $appServiceName
        -Name "Only Allow Traffic From Certain IP address"
        -Priority 100
        -Action Allow
        -IpAddress $allowedIpAddress
# Remember, this automatically adds another rule (with a lower priority) to deny traffic from all IP addresses 

# ----------------------
# Only allow traffic from a certain IP address to an Azure SQL server
# ----------------------
$sqlServerName = "sqlServer1"

# Add a rule to only allow traffic from the specified IP address
New-AzSqlServerFirewallRule
        -ResourceGroupName $resourceGroupName
        -ServerName $sqlServerName
        -FirewallRuleName "Allow Traffic From Certain IP address"
        -StartIpAddress $allowedIpAddress
        -EndIpAddress $allowedIpAddress

# Remember SQL server level firewall rules can be configured using powershell as the above example shows
# HOWEVER, SQL database level firewall rules can only be configured using T-SQL


