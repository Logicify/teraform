variable "target_subnet_id" {
  description = "VPC subnet to be used for placing teamcity VM"
}

variable "trusted_networks_ssh" {
  description = "The list of CIDRs to be whitelisted for SSH access"
}

variable "trusted_networks_webpanel" {
  description = "The list of CIDRs to be whitelisted for web panel (port 81)"
}

variable "trusted_networks_vpn" {
  description = "The list of CIDRs to be whitelisted for openvpn access"
  default = "0.0.0.0/0"
}

variable "default_security_group_ids" {
  default = []
  type = "list"
  description = "List of security groups IDs to be attached to all EC2 instances"
}

variable "instance_key_name" {}
variable "instance_type" {
  default = "t2.small"
}

variable "env_name" {
  description = "Name of the environment. Will be used as prefix for simplify objects identification"
}

variable "instance_data_volume_size" {
  default = 8
  description = "Size in GB for the root volume"
}

variable "instance_data_volume_device_name" {
  default = "/dev/sdb"
}

variable "centos_ami" {
  default = "ami-46c1b650"
}

variable "provisioning_key_path" {
  description = "Private key (.pem file) to be used for instance provisioning"
}

variable "enable_termination_protection" {
  default = true
}