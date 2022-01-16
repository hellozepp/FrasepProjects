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

variable "vm2vmtype" {
    type = string
}
variable "vm2disksizegb" {
    type = string
}

variable "vm3vmtype" {
    type = string
}
variable "vm3disksizegb" {
    type = string
}

variable "vm4vmtype" {
    type = string
}
variable "vm4disksizegb" {
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
  name     = "frasepViya35mpp_rg"
  location = var.location
  tags = {
        Environment = "Multi tier SAS Viya 3.5 environment"
        resourceowner = "frasep"
    }
}

###########################################################
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "frasepViya35mpp_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

###########################################################
# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "frasepViya35mpp_Subnet"
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

resource "azurerm_public_ip" "vm3publicip" {
  name                = "frasepViya35vm3_PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

data "azurerm_public_ip" "vm3ip" {
  name                = azurerm_public_ip.vm2publicip.name
  resource_group_name = azurerm_linux_virtual_machine.vm3.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.vm3]
}

resource "azurerm_public_ip" "vm4publicip" {
  name                = "frasepViya35vm4_PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

data "azurerm_public_ip" "vm4ip" {
  name                = azurerm_public_ip.vm4publicip.name
  resource_group_name = azurerm_linux_virtual_machine.vm4.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.vm4]
}

###########################################################
# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "frasepViya35mpp_NSG"
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
    source_address_prefixes    = ["149.173.0.0/16","90.127.106.134/32","86.238.106.195","10.0.0.0/16"]
    destination_address_prefix = "*"
  }

}

###########################################################
# Create network interface for vm1 (service and compute)
resource "azurerm_network_interface" "vm1nic" {
  name                      = "frasepViya35vm1_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm1NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.vm1publicip.id
  }
}

###########################################################
# Create network interface for vm2 (controller)
resource "azurerm_network_interface" "vm2nic" {
  name                      = "frasepViya35vm2_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm2NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.5"
    public_ip_address_id          = azurerm_public_ip.vm2publicip.id
  }
}

###########################################################
# Create network interface for vm3 (worker 1)
resource "azurerm_network_interface" "vm3nic" {
  name                      = "frasepViya35vm3_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm3NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.6"
    public_ip_address_id          = azurerm_public_ip.vm3publicip.id
  }
}

###########################################################
# Create network interface for vm3 (worker 2)
resource "azurerm_network_interface" "vm4nic" {
  name                      = "frasepViya35vm4_NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm4NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.7"
    public_ip_address_id          = azurerm_public_ip.vm4publicip.id
  }
}

###########################################################
# Create a Linux virtual machine (microservices and 
# compute engine)

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "frasepViya35vm1.cloud.com"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm1nic.id]
  size               = var.vm1vmtype
  depends_on          = [azurerm_linux_virtual_machine.vm2, azurerm_linux_virtual_machine.vm3, azurerm_linux_virtual_machine.vm4]

  disable_password_authentication = false
  computer_name  = "frasepViya35vm1.cloud.com"
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

  # Copies the ssh key files
  provisioner "file" {
    source      = "../key_viya.pub"
    destination = "/tmp/key_viya.pub"
    
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "../key_viya"
    destination = "/tmp/key_viya"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "./hosts_addin"
    destination = "/tmp/hosts_addin"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "../SAS_Viya_deployment_data.zip"
    destination = "/tmp/SAS_Viya_deployment_data.zip"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "./inventory_cas_multi_machine.ini"
    destination = "/tmp/inventory_cas_multi_machine.ini"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "./pre-install.inventory.ini"
    destination = "/tmp/pre-install.inventory.ini"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "./vars_mpp.yml"
    destination = "/tmp/vars.yml"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "./openldap_inventory.ini"
    destination = "/tmp/openldap_inventory.ini"
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
      "cat /tmp/hosts_addin | sudo tee -a /etc/hosts",
      "mkdir ~/.ssh",
      "chmod 700 ~/.ssh",
      "cat /tmp/key_viya.pub >> ~/.ssh/authorized_keys",
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
      "mv /tmp/pre-install.inventory.ini ./pre-install.inventory.ini",
      "ssh-keyscan frasepViya35vm2.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm3.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm4.cloud.com >> ~/.ssh/known_hosts",
      "ansible-playbook viya_pre_install_playbook.yml -i pre-install.inventory.ini --skip-tags skipmemfail",
      "cd ~/sas_viya_playbook",
      "mv /tmp/inventory_cas_multi_machine.ini ./inventory.ini",
      "cd ~/FrasepProjects/OpenLDAP_forViya3",
      "mv /tmp/openldap_inventory.ini ./inventory.ini",
      "ansible-playbook gel.openldapsetup.yml --skip-tags user_login",
      "cp ./sitedefault.yml  ~/sas_viya_playbook/roles/consul/files/sitedefault.yml",
      "cd ~/sas_viya_playbook",
      "mv /tmp/vars.yml ./vars.yml",
      "ansible-playbook site.yml",
      "sudo su - sas",
      "source /opt/sas/viya/config/consul.conf",
      "export CONSUL_TOKEN=`cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token`",
      "/opt/sas/viya/home/bin/sas-bootstrap-config kv write --force --key config/launcher-server/global/environment/SASMAKEHOMEDIR --value 1",
      "exit",
      "sudo systemctl restart sas-viya-runlauncher-default"
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
  name                  = "frasepViya35vm2.cloud.com"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm2nic.id]
  size                  = var.vm2vmtype

  disable_password_authentication = false
  computer_name  = "frasepViya35vm2.cloud.com"
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

  # Copies the ssh key file
  provisioner "file" {
    source      = "../key_viya.pub"
    destination = "/tmp/key_viya.pub"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }


  provisioner "file" {
    source      = "./hosts_addin"
    destination = "/tmp/hosts_addin"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }
  provisioner "file" {
    source      = "../key_viya"
    destination = "/tmp/key_viya"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
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
      "cat /tmp/hosts_addin | sudo tee -a /etc/hosts",
      "mkdir ~/.ssh",
      "chmod 700 ~/.ssh",
      "cat /tmp/key_viya.pub >> ~/.ssh/authorized_keys",
      "mv /tmp/key_viya.pub ~/.ssh/id_rsa.pub",
      "mv /tmp/key_viya ~/.ssh/id_rsa",
      "chmod 600 ~/.ssh/*",
      "ssh-keyscan frasepViya35vm1.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm2.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm3.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm4.cloud.com >> ~/.ssh/known_hosts",
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
      "sudo blobfuse /mnt/viyarepo --tmp-path=/mnt/blobfusetmp --config-file=./fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other"
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
# Create a Linux virtual machine (worker 1)

resource "azurerm_linux_virtual_machine" "vm3" {
  name                  = "frasepViya35vm3.cloud.com"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm3nic.id]
  size                  = var.vm3vmtype

  disable_password_authentication = false
  computer_name  = "frasepViya35vm3.cloud.com"
  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    name              = "frasepViya35vm3_OsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = var.vm3disksizegb
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-LVM"
    version   = "latest"
  }

  # Copies the ssh key file
  provisioner "file" {
    source      = "../key_viya.pub"
    destination = "/tmp/key_viya.pub"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }


  provisioner "file" {
    source      = "./hosts_addin"
    destination = "/tmp/hosts_addin"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "../key_viya"
    destination = "/tmp/key_viya"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
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
      "cat /tmp/hosts_addin | sudo tee -a /etc/hosts",
      "mkdir ~/.ssh",
      "chmod 700 ~/.ssh",
      "cat /tmp/key_viya.pub >> ~/.ssh/authorized_keys",
      "mv /tmp/key_viya.pub ~/.ssh/id_rsa.pub",
      "mv /tmp/key_viya ~/.ssh/id_rsa",
      "chmod 600 ~/.ssh/*",
      "ssh-keyscan frasepViya35vm1.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm2.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm3.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm4.cloud.com >> ~/.ssh/known_hosts",
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
      "sudo blobfuse /mnt/viyarepo --tmp-path=/mnt/blobfusetmp --config-file=./fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other"
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
# Create a Linux virtual machine (worker 2)

resource "azurerm_linux_virtual_machine" "vm4" {
  name                  = "frasepViya35vm4.cloud.com"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm4nic.id]
  size                  = var.vm4vmtype

  disable_password_authentication = false
  computer_name  = "frasepViya35vm4.cloud.com"
  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    name              = "frasepViya35vm4_OsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = var.vm4disksizegb
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-LVM"
    version   = "latest"
  }

  # Copies the ssh key file
  provisioner "file" {
    source      = "../key_viya.pub"
    destination = "/tmp/key_viya.pub"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }


  provisioner "file" {
    source      = "./hosts_addin"
    destination = "/tmp/hosts_addin"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
  }

  provisioner "file" {
    source      = "../key_viya"
    destination = "/tmp/key_viya"
    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${self.public_ip_address}"
    }
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
      "cat /tmp/hosts_addin | sudo tee -a /etc/hosts",
      "mkdir ~/.ssh",
      "chmod 700 ~/.ssh",
      "cat /tmp/key_viya.pub >> ~/.ssh/authorized_keys",
      "mv /tmp/key_viya.pub ~/.ssh/id_rsa.pub",
      "mv /tmp/key_viya ~/.ssh/id_rsa",
      "chmod 600 ~/.ssh/*",
      "ssh-keyscan frasepViya35vm1.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm2.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm3.cloud.com >> ~/.ssh/known_hosts",
      "ssh-keyscan frasepViya35vm4.cloud.com >> ~/.ssh/known_hosts",
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
      "sudo blobfuse /mnt/viyarepo --tmp-path=/mnt/blobfusetmp --config-file=./fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other"
    ]

      connection {
        type     = "ssh"
        user     = "${var.admin_username}"
        password = "${var.admin_password}"
        host     = "${self.public_ip_address}"
      }
  }  
}