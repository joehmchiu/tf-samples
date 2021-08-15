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

# Reuse existing subnet
data "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = "rg-${var.prefix}"
    virtual_network_name = "${var.prefix}-vnet"
}

# Reuse existing Network Security Group and rules
data "azurerm_network_security_group" "nsg" {
    name = "${var.prefix}-nsg"
    resource_group_name  = "rg-${var.prefix}"
}

# Create public IP
resource "azurerm_public_ip" "pip" {
    count                        = var.instance_count
    name                         = "${var.prefix}-pubip-${format("%03d", count.index + 1)}"
    location                     = var.location
    resource_group_name          = "${data.azurerm_resource_group.rg.name}"
    allocation_method            = "Static"

    tags = {
        environment = var.tag
    }
}

# Create a new network interface card
resource "azurerm_network_interface" "nic" {
    count = var.instance_count
    name = "${var.prefix}-nic-${format("%03d", count.index + 1)}"
    location                  = var.location
    resource_group_name       = "${data.azurerm_resource_group.rg.name}"

    ip_configuration {
        name                          = "${var.prefix}-privateip-${format("%03d", count.index + 1)}"
        subnet_id                     = "${data.azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.pip[count.index].id}"
    }

    tags = {
        environment = var.tag
    }
}

# Combine NIC and NSG 
resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  count                     = var.instance_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = data.azurerm_network_security_group.nsg.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
    count                 = var.instance_count
    name                  = "${var.prefix}-vm-${format("%03d", count.index + 1)}"
    location              = var.location
    resource_group_name   = "${data.azurerm_resource_group.rg.name}"
    network_interface_ids = ["${azurerm_network_interface.nic[count.index].id}"]
    vm_size               = var.size

    storage_os_disk {
        name              = "${var.prefix}-osdisk-${format("%03d", count.index + 1)}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "vm-${var.prefix}-${format("%03d", count.index + 1)}"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = var.sshdata
        }
    }

    tags = {
        environment = var.tag
    }
}

locals {
  config = [
    for n in range(var.instance_count): templatefile("${path.module}/temp/ssh-config.tpl", {
      ip = "${azurerm_public_ip.pip[n].ip_address}",
      vm = "vm${format("%d", n+1)}"
    })
  ]
}

resource "local_file" "ssh" {
  count   = var.instance_count
  content = "${local.config[count.index]}"
  filename = "${path.module}/ssh-config${format("%d", count.index+1)}.yml"

  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/ssh-config${format("%d", count.index+1)}.yml"
  }
}

