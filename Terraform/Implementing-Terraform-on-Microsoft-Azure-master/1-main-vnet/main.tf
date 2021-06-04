#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "West Europe"
}


variable "vnet_cidr_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "subnet_names" {
  type    = list(string)
  default = ["web", "database"]
}

#############################################################################
# PROVIDERS
#############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}
provider "azurerm" {
  features {}  
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet-main" {
  source              = "Azure/network/azurerm"
  version             = "3.5.0"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  vnet_name           = var.resource_group_name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}
  tags = {
    purpose = "training"
    description  = "Terraform exercises"

  }

  depends_on = [azurerm_resource_group.rg]

}

#############################################################################
# OUTPUTS
#############################################################################

output "vnet_id" {
  value = module.vnet-main.vnet_id
}
