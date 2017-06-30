variable "env_name" {
  type = "string"
}

variable "verbose_name" {
  type = "string"
  description = "Human-friendly name, will be used to construct resources names. E.g. Graylog"
}

variable "vpc_id" {
  type = "string"
  description = "Id of the VPC to host faclities in"
}

variable "vpc_subnets" {
  type = "list"
  description = "List of VPC subnet ids to start servers in"
}

variable "vpc_security_groups" {
  type = "list"
  description = "Extra VPC security groups to be assigned"
  default = []
}

variable "vpc_dns_zone_id" {
  type = "string"
}

variable "ecs_cluster_name" {
  type = "string"
}

variable "ecs_instance_group" {
  type = "string"
  default = "grafana"
}

variable "instance_ami" {
  type = "string"
  description = "AMI of ECS optimized Amazon Linux in your region"
}

variable "instance_type" {
  type = "string"
  description = "Size of EC2 instance to use"
}

variable "instance_key_name" {
  type = "string"
  description = "SSH key name used to associate with EC2 instances"
}

variable "instance_storage_size" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
  description = "List of availability zones to spread facilities between"
}

variable "enable_termination_protection" {
  type = "string"
  description = "Whether we should protect EC2 instances from accident termination"
}

variable "data_volume_device" {
  type = "string"
  default = "/dev/sdh"
}

variable "data_volume_path" {
  type = "string"
  default = "/srv"
}

variable "trusted_networks" {
  type = "list"
  description = "List of network CIDRs to grant access"
  default = []
}

variable "grafana_version" {
  type = "string"
  default = "4.3.2"
}

variable "grafana_password" {
  type = "string"
}

variable "grafana_url" {
  type = "string"
}

variable "grafana_port" {
  default = 3000
}

variable "grafana_memory_limit" {
  description = "Amount of memory to allocate for grafana process"
}

variable "grafana_nodes_count" {
  default = 1
}

variable "grafana_tasks_count" {
  default = 1
}