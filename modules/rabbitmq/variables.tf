variable "vpc_id" {
  description = "ID of the VPC"
}
variable "target_subnet_id" {
  description = "VPC subnet to be used for placing teamcity VM"
}

variable "trusted_networks_amqp" {
  type = "list"
  description = "The list of CIDRs to be whitelisted for SSH access"
}

variable "trusted_networks_control_panel" {
  type = "list"
  description = "The list of CIDRs to be whitelisted for web panel (port 81)"
}


variable "default_security_group_ids" {
  default = []
  type = "list"
  description = "List of security groups IDs to be attached to all EC2 instances"
}

variable "enable_termination_protection" {
  default = true
}

variable "instance_key_name" {}

variable "instance_type" {
  default = "t2.small"
}

variable "env_name" {
  description = "Name of the environment. Will be used as prefix for simplify objects identification"
}

variable "ami" { }

variable "ecs_cluster" {
  default = "default"
}

variable "ecs_group_name" {
  default = "rabbitmq"
}
