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

variable "smtp_host" {
  type = "string"
  default = ""
}

variable "smtp_port" {
  default = 25
}

variable "smtp_user" {
  type = "string"
  default = ""
}

variable "smtp_password" {
  type = "string"
  default = ""
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

variable "graylog_version" {
  type = "string"
  default = "2.1.1-1"
}

variable "graylog_memory_limit" {
  type = "string"
  description = "RAM limit for container"
}

variable "graylog_url" {
  type = "string"
}

variable "graylog_nodes_count" {
  default = 1
}

variable "graylog_tasks_count" {
  default = 1
}

variable "graylog_is_master" {
  default = true
}

variable "graylog_password_secret" {
  type = "string"
}

variable "graylog_admin_sha2" {
  type = "string"
}

variable "graylog_sent_email_from" {
  type = "string"
  default = ""
}

variable "mongodb_url" {
  type = "string"
}

variable "elasticsearch_num_shards" {
  default = 5
}

variable "elasticsearch_num_replicas" {
  default = 0
}

variable "elasticsearch_url" {
  type = "string"
}

variable "elasticsearch_cluster_name" {
  type = "string"
  description = "Name of Elasticsearch cluster"
  default = "graylog"
}