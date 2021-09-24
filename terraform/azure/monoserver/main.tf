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

variable "vm1disksizegb" {
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
  name     = "frasepViya35monoserver_rg"
  location = var.location
  tags = {
        Environment = "Monoserver SAS Viya 3.5 environment"
        resourceowner = "frasep"
    }
}

###########################################################
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "frasepViya35monoserver_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

###########################################################
# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "frasepViya35monoserver_Subnet"
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

###########################################################
# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "frasepViya35monoserver_NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["22","636","80","443","5570"]
    source_address_prefixes    = ["149.173.0.0/16","90.127.106.134/32","10.0.0.0/16"]
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
# Create a Linux virtual machine (microservices and 
# compute engine)

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "frasepviya35smp.cloud.com"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm1nic.id]
  size               = var.vm1vmtype
  depends_on          = [azurerm_linux_virtual_machine.vm2]

  disable_password_authentication = false
  computer_name  = "frasepviya35smp.cloud.com"
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

  provisioner "file" {
    source      = "./SAS_Viya_deployment_data.zip"
    destination = "/tmp/SAS_Viya_deployment_data.zip"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
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
      "echo \"${azurerm_linux_virtual_machine.vm1.private_ip_address} ${azurerm_linux_virtual_machine.vm1.computer_name}\" | sudo tee -a /etc/hosts",
      "echo \"${azurerm_linux_virtual_machine.vm2.private_ip_address} ${azurerm_linux_virtual_machine.vm2.computer_name}\" | sudo tee -a /etc/hosts",
      "mkdir ~/.ssh",
      "chmod 700 ~/.ssh",
      "mv /tmp/key_viya.pub ~/.ssh/id_rsa.pub",
      "mv /tmp/key_viya ~/.ssh/id_rsa",
      "mv /tmp/SAS_Viya_deployment_data.zip ~/SAS_Viya_deployment_data.zip",
      "chmod 600 ~/.ssh/*",
      "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      "sudo yum install -y python python-setuptools python-devel openssl-devel",
      "sudo yum install -y python-pip gcc wget automake libffi-devel python-six",
      "sudo pip install pip==19.3.1",
      "sudo pip install setuptools==42.0.2",
      "sudo pip install ansible==3.0.0",
      "git clone https://github.com/sassoftware/viya-ark.git",
      "git clone https://github.com/frasep/FrasepProjects.git",
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo setenforce Permissive",
      "sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm",
      "sudo yum -y install blobfuse",
      "sudo mkdir -p /mnt/viyarepo",
      "sudo mkdir -p /mnt/blobfusetmp",
      "tee  ~/fuse_connection.cfg /dev/null << \"EOF\"",
      "accountName frasepstorage", 
      "accountKey pHW64tt3HqQSvKgZS5ez6ZNKe4idzqYXnYRvXd5sMODrNgArDOBtO42omzcicw1LTat9BBpuBVz1WnKQxVrGEg==",
      "containerName sasviya35mirror",
      "EOF",
      "chmod 600 fuse_connection.cfg",
      "sudo blobfuse /mnt/viyarepo --tmp-path=/mnt/blobfusetmp --config-file=./fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other",
      "sudo yum install -y java",
      "wget https://support.sas.com/installation/viya/35/sas-orchestration-cli/lax/sas-orchestration-linux.tgz",
      "tar xvf ./sas-orchestration-linux.tgz",
      "./sas-orchestration build --input ./SAS_Viya_deployment_data.zip --platform redhat --architecture x64 --repository-warehouse \"file:////mnt/viyarepo/Sept2021/viya_repo\"",
      "tar xvf SAS_Viya_playbook.tgz",
      "mv viya-ark/ ./sas_viya_playbook/",
      "sudo sed -i '/ClientAliveInterval/c\\ClientAliveInterval 3600' /etc/ssh/sshd_config",
      "cd ./sas_viya_playbook/viya-ark/playbooks/pre-install-playbook",
      "ansible-playbook viya_pre_install_playbook.yml -i pre-install.inventory.ini --skip-tags skipmemfail",
      "cd ~/sas_viya_playbook",
      "cp ./samples/inventory_local.ini inventory.ini",
      "cd ~/FrasepProjects/OpenLDAP_forViya3"
    ]

    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }
}
