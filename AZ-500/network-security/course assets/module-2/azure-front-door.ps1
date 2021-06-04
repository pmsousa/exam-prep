$resourceGroupName = 'rg-demo'
$webapp1Name = 'backendApp1-uksouth'
$webapp2Name = 'backendApp2-ukwest'

$FrontendEndHostName = 'demofrontdoor'

# Get two existing app services in different Azure regions
$webapp1 = Get-AzWebApp 
            -ResourceGroupName $resourceGroupName
            -Name $webapp1Name
$webapp2 = Get-AzWebApp 
            -ResourceGroupName $resourceGroupName
            -Name $webapp2Name

# Create the frontend object
$FrontendEndObject = New-AzFrontDoorFrontendEndpointObject
            -Name "frontendEndpoint1" `
            -HostName $FrontendEndDomainName".azurefd.net"


# Create backend objects that point to the hostnames of the web apps
$backendObject1 = New-AzFrontDoorBackendObject
            -Address $webapp1.DefaultHostName
$backendObject2 = New-AzFrontDoorBackendObject
            -Address $webapp2.DefaultHostName

# Create a health probe object
$HealthProbeObject = New-AzFrontDoorHealthProbeSettingObject
            -Name "HealthProbeSetting"

# Create a load balancing setting object
$LoadBalancingSettingObject = New-AzFrontDoorLoadBalancingSettingObject
            -Name "Loadbalancingsetting"
            -SampleSize "4"
            -SuccessfulSamplesRequired "2"
            -AdditionalLatencyInMilliseconds "0"

# Create a backend pool using the backend objects, health probe, and load balancing settings
$BackendPoolObject = New-AzFrontDoorBackendPoolObject
            -Name "backendPool1"
            -FrontDoorName $FrontendEndHostName
            -ResourceGroupName $resourceGroupName
            -Backend $backendObject1,$backendObject2
            -HealthProbeSettingsName "HealthProbeSetting" `
            -LoadBalancingSettingsName "Loadbalancingsetting"


# Create a default routing rule to map the frontend host to the backend pool
$RoutingRuleObject = New-AzFrontDoorRoutingRuleObject
            -Name "LocationRule"
            -FrontDoorName $fdname
            -ResourceGroupName myResourceGroupFD
            -FrontendEndpointName "frontendEndpoint1"
            -BackendPoolName "myBackendPool"
            -PatternToMatch "/*"


# Create the Front Door
$frontDoor = New-AzFrontDoor
            -Name $fdname 
            -ResourceGroupName $resourceGroupName
            -RoutingRule $RoutingRuleObject
            -BackendPool $BackendPoolObject
            -FrontendEndpoint $FrontendEndObject
            -LoadBalancingSetting $LoadBalancingSettingObject
            -HealthProbeSetting $HealthProbeObject



