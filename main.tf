module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "random_shuffle" "region" {
  input        = ["ca-tor", "jp-osa", "au-syd", "jp-tok"]
  result_count = 1
}

resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh.private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}

module "vpc" {
  source                      = "terraform-ibm-modules/vpc/ibm//modules/vpc"
  version                     = "1.1.1"
  create_vpc                  = true
  vpc_name                    = "${local.prefix}-vpc"
  resource_group_id           = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  default_address_prefix      = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  vpc_tags                    = local.tags
  locations                   = [local.vpc_zones[0].zone]
  number_of_addresses         = "128"
  create_gateway              = true
  subnet_name                 = "${local.prefix}-frontend-subnet"
  public_gateway_name         = "${local.prefix}-pub-gw"
  gateway_tags                = local.tags
}


module "security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = module.vpc.vpc_id[0]
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.frontend_rules
}



resource "ibm_is_instance" "bastion" {
  name                     = "${local.prefix}-bastion"
  vpc                      = module.vpc.vpc_id[0]
  image                    = data.ibm_is_image.base.id
  profile                  = var.instance_profile
  resource_group           = module.resource_group.resource_group_id
  metadata_service_enabled = var.metadata_service_enabled

  boot_volume {
    name = "${local.prefix}-boot-volume"
  }

  primary_network_interface {
    subnet            = module.vpc.subnet_ids[0]
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.security_group.security_group_id[0]]
  }
  # Need to strip out logging and monitoring key from installer script 
  # Use installer for consul, nomad, vault  
  # user_data = templatefile("${path.module}/init.tftpl", { logdna_ingestion_key = module.logging.logdna_ingestion_key, region = local.region, vpc_tag = "vpc:${local.prefix}-vpc" })
  zone = local.vpc_zones[0].zone
  keys = local.ssh_key_ids
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-bastion-public-ip"
  resource_group = module.resource_group.resource_group_id
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

# resource "null_resource" "bastion" {
#   depends_on = [ibm_is_floating_ip.bastion]
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Bastion IP: ${ibm_is_floating_ip.bastion.address}"
#       echo "Bastion SSH Key: ${local.prefix}.pem"
#     EOT
#   }
# }

## Add instance template here
## Add instance group here
## Add LB as frontend for instance group

## Need to be able to pull members from instance group and get private IP

# data ibm_is_instance_group_members 
# add depends on for instance group itself 
# Update inventory.tmpl to use instance group members

# resource "local_file" "ansible-inventory" {
#   content = templatefile("${path.module}/inventory.tmpl",
#     {
#       instances = concat(
#         ibm_is_instance.pool1.*,
#         ibm_is_instance.pool2.*
#       )
#       bastion_ip = ibm_is_floating_ip.bastion.address
#     }
#   )
#   filename = "${path.module}/inventory.ini"
# }