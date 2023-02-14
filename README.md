# ibmcloud-mzr-lab

Terraform code to deploy an IBM Cloud MZR VPC with a VPN or Bastion host. This is a work in progress and currently creates:

 - :white_check_mark:  MZR VPC 
 - :white_check_mark:  Public Gateway per zone for Frontend subnets
 - :white_check_mark:  Frontend subnet per zone 
 - :white_check_mark:  Frontend Security Group for SSH, Web, and VPN
    - Inbound: `80/tcp`, `443/tcp`, `22/tcp`, `51280/udp`
    - Outbound: `all`
 - :white_check_mark:  Cloud Object Storage instance for flowlogs (target existing or create new)
 - :white_check_mark:  IAM Authorization policy so that Flowlogs can write to the COS instance.
 - :white_check_mark:  COS bucket for each Frontend subnet  
 - :white_check_mark:  Flowlogs collector for each Frontend subnet 
 - :white_check_mark:  Logging instance with ability to use existing instance or deploy new one
 - :x: VPN server with Wireguard 
 - :white_check_mark:  Bastion Server 

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cos"></a> [cos](#module\_cos) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cos | v5.3.1 |
| <a name="module_fowlogs_cos_bucket"></a> [fowlogs\_cos\_bucket](#module\_fowlogs\_cos\_bucket) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cos | v5.3.1 |
| <a name="module_logging"></a> [logging](#module\_logging) | git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances | main |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git | v1.0.5 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-ibm-modules/vpc/ibm//modules/security-group | 1.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-ibm-modules/vpc/ibm//modules/vpc | 1.1.1 |

## Resources

| Name | Type |
|------|------|
| [ibm_iam_authorization_policy.cos_flowlogs](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/iam_authorization_policy) | resource |
| [ibm_is_floating_ip.bastion](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/is_floating_ip) | resource |
| [ibm_is_flow_log.frontend](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/is_flow_log) | resource |
| [ibm_is_instance.bastion](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/is_instance) | resource |
| [ibm_is_ssh_key.generated_key](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/is_ssh_key) | resource |
| [null_resource.create_private_key](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_shuffle.region](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [ibm_is_image.base](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/is_image) | data source |
| [ibm_is_ssh_key.sshkey](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/is_ssh_key) | data source |
| [ibm_is_zones.regional](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/is_zones) | data source |
| [ibm_resource_instance.cos](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/resource_instance) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_ip_spoofing"></a> [allow\_ip\_spoofing](#input\_allow\_ip\_spoofing) | Allow IP spoofing on the bastion instance primary interface. | `bool` | `false` | no |
| <a name="input_classic_access"></a> [classic\_access](#input\_classic\_access) | Allow classic access to the VPC. | `bool` | `false` | no |
| <a name="input_default_address_prefix"></a> [default\_address\_prefix](#input\_default\_address\_prefix) | The address prefix to use for the VPC. Default is set to auto. | `string` | `"auto"` | no |
| <a name="input_existing_cos_instance"></a> [existing\_cos\_instance](#input\_existing\_cos\_instance) | The name of an existing COS instance to use. If not specified, a new instance will be created. | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Resource group to use for all deployed resources. If not specified, a new one will be created. | `string` | n/a | yes |
| <a name="input_existing_ssh_key"></a> [existing\_ssh\_key](#input\_existing\_ssh\_key) | The name of an existing SSH key to use. If not specified, a new key will be created. | `string` | `""` | no |
| <a name="input_frontend_rules"></a> [frontend\_rules](#input\_frontend\_rules) | A list of security group rules to be added to the Frontend security group | <pre>list(<br>    object({<br>      name      = string<br>      direction = string<br>      remote    = string<br>      tcp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      udp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      icmp = optional(<br>        object({<br>          type = optional(number)<br>          code = optional(number)<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-vpn-udp",<br>    "remote": "0.0.0.0/0",<br>    "udp": {<br>      "port_max": 51280,<br>      "port_min": 51280<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-http",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 80,<br>      "port_min": 80<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-https",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 443,<br>      "port_min": 443<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-ssh",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 22,<br>      "port_min": 22<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "icmp": {<br>      "code": 0,<br>      "type": 8<br>    },<br>    "ip_version": "ipv4",<br>    "name": "inbound-icmp",<br>    "remote": "0.0.0.0/0"<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "all-outbound",<br>    "remote": "0.0.0.0/0"<br>  }<br>]</pre> | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | The name of an existing OS image to use. You can list available images with the command 'ibmcloud is images'. | `string` | `"ibm-ubuntu-22-04-1-minimal-amd64-3"` | no |
| <a name="input_instance_profile"></a> [instance\_profile](#input\_instance\_profile) | The name of an existing instance profile to use. You can list available instance profiles with the command 'ibmcloud is instance-profiles'. | `string` | `"cx2-2x4"` | no |
| <a name="input_metadata_service_enabled"></a> [metadata\_service\_enabled](#input\_metadata\_service\_enabled) | Enable the metadata service on the bastion instance. | `bool` | `true` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Project owner or identifier. This is used as a tag on all supported resources. | `string` | n/a | yes |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix to be added to all deployed resources. If none provided, one will be automatically generated. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud Region where resources will be deployed. If not specified, one will be randomly selected. To see available regions, run 'ibmcloud is regions'. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP of the bastion instance. |
| <a name="output_cos_bucket_names"></a> [cos\_bucket\_names](#output\_cos\_bucket\_names) | n/a |
| <a name="output_cos_instance_guid"></a> [cos\_instance\_guid](#output\_cos\_instance\_guid) | The details of the COS instance. |
| <a name="output_frontend_subnet_ids"></a> [frontend\_subnet\_ids](#output\_frontend\_subnet\_ids) | The IDs of the frontend subnets. |
| <a name="output_public_gateway_ids"></a> [public\_gateway\_ids](#output\_public\_gateway\_ids) | The IDs of the public gateways. |
| <a name="output_region"></a> [region](#output\_region) | IBM Cloud Region where resources are deployed. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
