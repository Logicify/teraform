variable "env_name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "vpc_subnets" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "verbose_name" {
  type = "string"
  default = ""
  description = "Will be used in resources names. E.g. Graylog"
}

variable "enable_termination_protection" {
  type = "string"
  default = true
}

variable "security_groups" {
  type = "list"
  default = []
  description = "Extra security groups to be assigned"
}

variable "instance_key_name" {
  type = "string"
  description = "EC2 instance key name"
}

variable "ami_id" {
  type = "string"
}

variable "instance_type" {
  type = "string"
  default = "t2.small"
}

variable "elasticsearch_cluster_name" {
  type = "string"
}

variable "ecs_cluster_name" {
  type = "string"
}

variable "instances_count" {
  type = "string"
  default = 1
}

variable "data_volume_device" {
  type = "string"
  default = "/dev/sdh"
}

variable "data_volume_device" {
  type = "string"
  default = "/dev/sdh"
}

variable "data_volume_path" {
  type = "string"
  default = "/srv/elasticseach-data"
}

variable container_memory_limit {
  default = "2048"
  description = "RAM limit for container"
}

variable "storage_size" {
  type = "string"
}

variable "http_trusted_networks" {
  type = "list"
}

variable "native_trusted_networks" {
  type = "list"
}

variable "elasticsearch_version" {
  type = "string"
  default = "5.2.2"
}
