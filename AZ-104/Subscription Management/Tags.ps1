Login-AzAccount

$subscription = Get-AzSubscription | Out-GridView -OutputMode Single -Title 'Select subscription'

Set-AzContext -Subscription $subscription


Get-AzTag -Detailed

