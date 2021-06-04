$resourceGroupName = "rg-demo"
$region = "westeurope"

# Create a custom rule to block a malicious bot with a user-agent that contains 'badbot'
$matchVariable = New-AzApplicationGatewayFirewallMatchVariable
        -VariableName RequestHeaders
        -Selector User-Agent

$condition = New-AzApplicationGatewayFirewallCondition
        -MatchVariable $matchVariable
        -Operator Contains
        -MatchValue "badbot"
        -Transform Lowercase
        -NegationCondition $False

$rule1 = New-AzApplicationGatewayFirewallCustomRule
        -Name "blockEvilBot"
        -Priority 2 
        -RuleType MatchRule 
        -MatchCondition $condition 
        -Action Block

# Create a WAF policy with the custom rule you created
$wafPolicy = New-AzApplicationGatewayFirewallPolicy
        -Name wafpolicyNew
        -ResourceGroup $resourceGroupName
        -Location $region
        -CustomRule $rule1


# Get an existing application gateway
$applicationGateway = Get-AzApplicationGateway
            -Name "appGateway1"
            -ResourceGroupName $resourceGroupName

# Enable the firewall on the application gateway in prevention mode (Traffic matching the OWASP security rules will then be blocked)            
Set-AzApplicationGatewayWebApplicationFirewallConfiguration
            -ApplicationGateway $applicationGateway
            -Enabled $True
            -FirewallMode "Prevention"
            -RuleSetType "OWASP"
            -RuleSetVersion "3.0"

# Attach the WAF policy to the application gateway
$applicationGateway.FirewallPolicy = $wafPolicy

# Update the application gateway
# Your custom rule will now be applied along with the OWASP rules 
Set-AzApplicationGateway -ApplicationGateway $applicationGateway
