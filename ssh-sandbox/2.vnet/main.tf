terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

# Create a resource group if it doesn’t exist
data "azurerm_resource_group" "rg" {
    name     = "rg-${var.prefix}"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.prefix}-vnet"
    address_space       = [var.vnet_cidr]
    location            = var.location
    resource_group_name = "rg-${var.prefix}"

    tags = {
        environment = var.tag
    }
}

