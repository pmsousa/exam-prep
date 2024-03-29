#############################################################################
# VARIABLES
#############################################################################

variable "sec_resource_group_name" {
  type    = string
  default = "security"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "vnet_cidr_range" {
  type    = string
  default = "10.1.0.0/16"
}

variable "sec_subnet_prefixes" {
  type    = list(string)
  default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "sec_subnet_names" {
  type    = list(string)
  default = ["siem", "inspect"]
}

#############################################################################
# DATA
#############################################################################

data "azurerm_subscription" "current" {}

#############################################################################
# PROVIDERS
#############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.61.0"
    }

    azuread = {
      source = "hashicorp/azuread"
      version = "1.5.0"
    }
  }

}


provider "azurerm" {
  features {
    
  }
}

provider "azuread" {

}

#############################################################################
# RESOURCES
#############################################################################


resource "azurerm_resource_group" "rg" {
  name     = var.sec_resource_group_name
  location = var.location
}

## NETWORKING ##

module "vnet-sec" {
  source              = "Azure/network/azurerm"
  version             = "3.5.0"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = azurerm_resource_group.rg.name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.sec_subnet_prefixes
  subnet_names        = var.sec_subnet_names

  tags = {
    purpose = "training"
    description  = "Terraform exercises"
  }

  depends_on = [azurerm_resource_group.rg]

}

## AZURE AD SP ##


resource "random_password" "vnet_peering" {
  length  = 16
  special = true
}

resource "azuread_application" "vnet_peering" {
  name = "vnet-peer"
}

resource "azuread_service_principal" "vnet_peering" {
  application_id = azuread_application.vnet_peering.application_id
}

resource "azuread_service_principal_password" "vnet_peering" {
  service_principal_id = azuread_service_principal.vnet_peering.id
  value                = random_password.vnet_peering.result
  end_date_relative    = "17520h"
}

resource "azurerm_role_definition" "vnet-peering" {
  name     = "allow-vnet-peering"
  scope    = data.azurerm_subscription.current.id

#Microsoft Actions Reference: https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations
  permissions {
    actions     = ["Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write", "Microsoft.Network/virtualNetworks/peer/action", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]
}

resource "azurerm_role_assignment" "vnet" {
  scope              = module.vnet-sec.vnet_id
  role_definition_id = split("|",azurerm_role_definition.vnet-peering.id)[0]
  principal_id       = azuread_service_principal.vnet_peering.id
}

#############################################################################
# PROVISIONERS
#############################################################################

resource "null_resource" "post-config" {

  depends_on = [azurerm_role_assignment.vnet]

  provisioner "local-exec" {
    command = <<EOT
echo "export TF_VAR_sec_vnet_id=${module.vnet-sec.vnet_id}" >> next-step.txt
echo "export TF_VAR_sec_vnet_name=${module.vnet-sec.vnet_name}" >> next-step.txt
echo "export TF_VAR_sec_sub_id=${data.azurerm_subscription.current.subscription_id}" >> next-step.txt
echo "export TF_VAR_sec_client_id=${azuread_service_principal.vnet_peering.application_id}" >> next-step.txt
echo "export TF_VAR_sec_principal_id=${azuread_service_principal.vnet_peering.id}" >> next-step.txt
echo "export TF_VAR_sec_client_secret='${random_password.vnet_peering.result}'" >> next-step.txt
echo "export TF_VAR_sec_resource_group=${var.sec_resource_group_name}" >> next-step.txt
EOT
  }
}

#############################################################################
# OUTPUTS
#############################################################################

output "vnet_id" {
  value = module.vnet-sec.vnet_id
}

output "vnet_name" {
  value = module.vnet-sec.vnet_name
}

output "service_principal_client_id" {
  value = azuread_service_principal.vnet_peering.id
}

output "service_principal_client_secret" {
  value = random_password.vnet_peering.result
  sensitive = true
}

output "resource_group_name" {
  value = var.sec_resource_group_name
}