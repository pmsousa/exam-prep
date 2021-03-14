Login-AzAccount

$subscription = Get-AzSubscription | Out-GridView -OutputMode Single -Title 'Select subscription'

Set-AzContext -Subscription $subscription


Get-AzTag -Detailed

$resource = Get-AzResourceGroup -Name 'RG-SQLIO'

$tags = @{'Description' = 'SQLIO'}

Update-aztag -ResourceId $resource.ResourceId -Tag $tags -Operation Replace

Get-AzTag -ResourceId $resource.ResourceId

$allResources = Get-AzResource -ResourceGroupName $resource.ResourceGroupName
foreach ($obj in $allResources) {
    Update-AzTag -ResourceId $obj.ResourceId -Tag $tags -Operation Replace
    
}