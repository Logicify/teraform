variable "env_name" {
  type = "string"
  description = "Environment name"
}

variable "verbose_name" {
  type = "string"
  description = "Human-friendly name that will be used to construct resources names. E.g. Graylog"
}

variable "elasticsearch_version" {
  type = "string"
  description = "Elasticsearch version to use"
  default = "5.4.2"
}

variable "elasticsearch_memory_limit" {
  description = "Ammount of memory to allocate for elasticsearch containers"
}

variable "elasticsearch_cluster_name" {
  type = "string"
  description = "Name of Elasticsearch cluster"
}

variable "master_nodes_count" {
  description = "Number of dedicated master eiligible nodes in cluster. Master nodes doesn't store any data and used only to control the cluster itself"
  default = 0
}

variable "data_nodes_count" {
  description = "Number of data nodes in cluster. Data nodes hold the shards and run cluster CRUD operations"
  default = 1
}

variable "external_masters_addresses" {
  type = "list"
  default = []
}

variable "is_data_nodes_master_eiligible" {
  description = "Wheter we should allow data nodes to be elected as master"
  default = true
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

variable "instance_ami" {
  type = "string"
  description = "AMI of ECS optimized Amazon Linux in your region"
}

variable "master_instance_type" {
  type = "string"
  description = "Size of EC2 instance to use for dedicated elasticsearch master"
  default = "t2.micro"
}

variable "data_instance_type" {
  type = "string"
  description = "Size of EC2 instance to use for elasticsearch data nodes, please be aware of elasticsearch_memory_limit value"
}

variable "instance_key_name" {
  type = "string"
  description = "SSH key name used to associate with EC2 instances"
}

variable "data_instance_storage_size" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
  description = "List of availability zones to spread facilities between"
}

variable "trusted_networks" {
  type = "list"
  description = "List of network CIDRs to grant access to elasticsearch"
  default = []
}

variable "enable_termination_protection" {
  type = "string"
  description = "Whether we should protect EC2 instances from accident termination"
  default = true
}

variable "ecs_cluster_name" {
  type = "string"
  description = "Name of ecs cluster to start in"
}

variable "data_volume_device" {
  type = "string"
  default = "/dev/sdh"
}

variable "data_volume_path" {
  type = "string"
  default = "/srv/elasticseach-data"
}

variable "vpc_dns_zone_id" {
  type = "string"
}