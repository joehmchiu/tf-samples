terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

# Reuse the existing resource group 
data "azurerm_resource_group" "rg" {
    name = "rg-${var.prefix}"
}

# Reuse the existing virtual network
data "azurerm_virtual_network" "vnet" {
    name = "${var.prefix}-vnet"
    resource_group_name = "rg-${var.prefix}"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = "rg-${var.prefix}"
    virtual_network_name = "${var.prefix}-vnet"
    address_prefixes     = [var.subnet_cidr]
}

