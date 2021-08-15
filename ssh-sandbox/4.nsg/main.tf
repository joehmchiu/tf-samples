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

# Reuse the existing subnet
data "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = "rg-${var.prefix}"
    virtual_network_name = "${var.prefix}-vnet"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.prefix}-nsg"
    location            = var.location
    resource_group_name = "rg-${var.prefix}"

    security_rule {
        name                       = "ssh-access"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "mysql-access"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.tag
    }
}


