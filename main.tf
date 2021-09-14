#define bigip provider
terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.4.0"
    }
  }
  required_version = ">= 0.13"
}
provider "bigip" {
  address  = "192.168.2.245"
  username = "admin"
  password = "admin"
}

#Update main.tf file to include ntp resource
resource "bigip_sys_ntp" "ntp1" {
  description = "/Common/NTP1"
  servers     = ["time.google.com"]
  timezone    = "America/Los_Angeles"
}

#Update main.tf file to include dns resource
resource "bigip_sys_dns" "dns1" {
  description    = "/Common/DNS1"
  name_servers   = ["8.8.8.8"]
  number_of_dots = 2
  search         = ["f5.com"]
}

#Update main.tf file to include external vlan resource
resource "bigip_net_vlan" "vlan1" {
  name = "/Common/F5_INT"
  tag  = 101
  interfaces {
    vlanport = 1.2
    tagged   = false
  }
}

#Update main.tf file to include external vlan resource
resource "bigip_net_vlan" "vlan2" {
  name = "/Common/F5_EXT"
  tag  = 102
  interfaces {
    vlanport = 1.1
    tagged   = false
  }
}

#Update main.tf file to include Internal Self IP resource
resource "bigip_net_selfip" "selfip1" {
  name = "/Common/F5_INT_SELF_IP"
  ip   = "10.128.20.245/24"
  vlan = bigip_net_vlan.vlan1.name
}

#Update main.tf file to include External Self IP resource
resource "bigip_net_selfip" "selfip2" {
  name = "/Common/F5_EXT_SELF_IP"
  ip   = "10.128.10.245/24"
  vlan = bigip_net_vlan.vlan2.name
}


#Update main.tf file to include default static route
resource "bigip_net_route" "route2" {
  name       = "default_route"
  network    = "default"
  gw         = "10.128.10.1"
  depends_on = [bigip_net_selfip.selfip2]
}


#Create Simple VS, Pool etc using BIG-IP Terraform resources

#Update main.tf file to include http monitoring
resource "bigip_ltm_monitor" "monitor" {
  name     = "/Common/terraform_monitor"
  parent   = "/Common/http"
  send     = "GET /\r\n"
  timeout  = "31"
  interval = "10"
}

#Update main.tf file to include nodes
resource "bigip_ltm_node" "node1" {
  name             = "/Common/terraform_node1"
  address          = "10.128.20.11"
  connection_limit = "0"
  dynamic_ratio    = "1"
  monitor          = "/Common/icmp"
  description      = "Test-Node"
  rate_limit       = "disabled"
  fqdn {
    address_family = "ipv4"
    interval       = "3000"
  }
}
resource "bigip_ltm_node" "node2" {
  name             = "/Common/terraform_node2"
  address          = "10.128.20.12"
  connection_limit = "0"
  dynamic_ratio    = "1"
  monitor          = "/Common/icmp"
  description      = "Test-Node"
  rate_limit       = "disabled"
  fqdn {
    address_family = "ipv4"
    interval       = "3000"
  }
}


#Update main.tf file to include Server Pool
resource "bigip_ltm_pool" "pool" {
  name                = "/Common/terraform-pool"
  load_balancing_mode = "round-robin"
  monitors            = [bigip_ltm_monitor.monitor.name]
  allow_snat          = "yes"
  allow_nat           = "yes"
}


#Update main.tf file to Attach Node or include member in Pool
resource "bigip_ltm_pool_attachment" "attach_node1" {
  pool = bigip_ltm_pool.pool.name
  node = "${bigip_ltm_node.node1.name}:80"
}
resource "bigip_ltm_pool_attachment" "attach_node2" {
  pool = bigip_ltm_pool.pool.name
  node = "${bigip_ltm_node.node2.name}:80"
}


#Update main.tf file to Create a Virtual Server using Pool
resource "bigip_ltm_virtual_server" "http" {
  pool                       = bigip_ltm_pool.pool.name
  name                       = "/Common/terraform_vs_http"
  destination                = "10.128.10.100"
  port                       = 80
  source_address_translation = "automap"
}


# #download rpm and install to BIG-IP
# resource "null_resource" "download_as3" {
#   provisioner "local-exec" {
#     command = "wget https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.21.0/f5-appsvcs-3.21.0-4.noarch.rpm"
#   }
# }
# # install rpm to BIG-IP
# resource "null_resource" "install_as3" {
#   provisioner "local-exec" {
#     command = "./install_as3.sh 192.168.2.245 admin:admin f5-appsvcs-3.21.0-4.noarch.rpm"
#   }
#   depends_on = [null_resource.download_as3]
# }

# #deploying example1.json as3 declaration
# resource "bigip_as3" "http_as3" {
#   as3_json   = file("example1.json")
#   depends_on = [null_resource.install_as3]
# }


# #Provision ASM module
# resource "bigip_sys_provision" "asm" {
#   name         = "asm"
#   full_path    = "/Common/asm"
#   cpu_ratio    = 0
#   disk_ratio   = 0
#   level        = "nominal"
#   memory_ratio = 0
#   depends_on   = [bigip_as3.http_as3]
# }

# #deploying example2.json as3 declaration
# resource "bigip_as3" "http_waf_as3" {
#   as3_json   = file("example2.json")
#   depends_on = [null_resource.install_as3]
# }
