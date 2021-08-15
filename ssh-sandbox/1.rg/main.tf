terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
    name     = "rg-${var.prefix}"
    location = var.location

    tags = {
        environment = var.tag
    }
}

