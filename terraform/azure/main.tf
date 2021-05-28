###########################################################
# Declare all variables
###########################################################

variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
}

variable "location" {
    type = string
}

variable "vm1vmtype" {
    type = string
}

variable "vm2vmtype" {
    type = string
}

variable "vm1disksizegb" {
    type = string
}

variable "vm2disksizegb" {
    type = string
}

###########################################################
# End of variable declaration block
###########################################################

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "frasepViya35multiTier_rg"
  location = var.location
  tags = {
        Environment = "Multi tier SAS Viya 3.5 environment"
        resourceowner = "frasep"
    }
}

###########################################################
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "frasepViya35multiTier_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

###########################################################
# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "frasepViya35multiTier_Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

###########################################################
# Create public IP
resource "azurerm_public_ip" "vm1publicip" {
  name                = "frasepViya35vm1_PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

data "azurerm_public_ip" "vm1ip" {
  name                = azurerm_public_ip.vm1publicip.name
  resource_group_name = azurerm_linux_virtual_machine.vm1.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.vm1]
}

resource "azurerm_public_ip" "vm2publicip" {
  name                = "frasepViya35vm2_PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

data "azurerm_public_ip" "vm2ip" {
  name                = azurerm_public_ip.vm2publicip.name
  resource_group_name = azurerm_linux_virtual_machine.vm2.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.vm2]
}

###########################################################
# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "frasepViya35multiTier_NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["149.173.0.0/16","86.238.109.83/32"]
    destination_address_prefix = "*"
  }
}

###########################################################
# Create network interface for vm1
resource "azurerm_network_interface" "vm1nic" {
  name                      = "frasepViya35vm1_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm1NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1publicip.id
  }
}

###########################################################
# Create network interface for vm2
resource "azurerm_network_interface" "vm2nic" {
  name                      = "frasepViya35vm2_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm2NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2publicip.id
  }
}

###########################################################
# Create a Linux virtual machine (microservices and 
# compute engine)

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "frasepViya35vm1"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm1nic.id]
  size               = var.vm1vmtype
  depends_on          = [azurerm_linux_virtual_machine.vm2]

  disable_password_authentication = false
  computer_name  = "frasepViya35vm1"
  admin_username = var.admin_username
  admin_password = var.admin_password
  
  os_disk {
    name                 = "frasepViya35vm1_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = var.vm1disksizegb
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-LVM"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y cloud-utils-growpart gdisk git",
      "sudo growpart /dev/sda 4",
      "sudo pvresize /dev/sda4",
      "sudo lvresize -r -L +100G /dev/rootvg/tmplv",
      "sudo lvresize -r -L +10G /dev/rootvg/usrlv",
      "sudo lvresize -r -L +120G /dev/rootvg/optlv",
      "sudo lvresize -r -L +10G /dev/rootvg/homelv",
      "sudo lvresize -r -L +10G /dev/rootvg/varlv",
      "sudo lvresize -r -L +5G /dev/rootvg/rootlv",
      "ssh-keygen -t dsa -N \"My viya 35 env\" -C \"secured\" -f ~/.ssh/id_viya",
      "ssh-copy-id -i ~/.ssh/id_viya.pub ${var.admin_username}@${azurerm_linux_virtual_machine.vm2.public_ip_address}",
      "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$majversion.noarch.rpm",
      "sudo yum install -y python python-setuptools python-devel openssl-devel",
      "sudo yum install -y python-pip gcc wget automake libffi-devel python-six",
      "sudo pip install -y pip==19.3.1",
      "sudo pip install -y setuptools==42.0.2",
      "sudo pip install -y ansible==2.7.2",
      "git clone https://github.com/sassoftware/viya-ark.git",
    ]

    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }
}

###########################################################
# Create a Linux virtual machine (controller)

resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "frasepViya35vm2"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm2nic.id]
  size                  = var.vm2vmtype

  disable_password_authentication = false
  computer_name  = "frasepViya35vm2"
  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    name              = "frasepViya35vm2_OsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = var.vm2disksizegb
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-LVM"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install cloud-utils-growpart gdisk",
      "sudo growpart /dev/sda 4",
      "sudo pvresize /dev/sda4",
      "sudo lvresize -r -L +100G /dev/rootvg/tmplv",
      "sudo lvresize -r -L +10G /dev/rootvg/usrlv",
      "sudo lvresize -r -L +120G /dev/rootvg/optlv",
      "sudo lvresize -r -L +10G /dev/rootvg/homelv",
      "sudo lvresize -r -L +10G /dev/rootvg/varlv",
      "sudo lvresize -r -L +5G /dev/rootvg/rootlv",
    ]

      connection {
        type     = "ssh"
        user     = "${var.admin_username}"
        password = "${var.admin_password}"
        host     = "${self.public_ip_address}"
      }
  }  
}
