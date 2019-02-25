variable "env_name" {
  type = "string"
  description = "Environment name"
}

variable "verbose_name" {
  type = "string"
  description = "Human-friendly name that will be used to construct resources names. E.g. Graylog"
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
  description = "Name of ecs cluster to start in"
}

variable "ecs_instance_group" {
  type = "string"
  default = "elasticsearch"
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

variable "instance_type" {
  type = "string"
  description = "Size of EC2 instance to use for elasticsearch data nodes, please be aware of elasticsearch_memory_limit value"
}

variable "instance_key_name" {
  type = "string"
  description = "SSH key name used to associate with EC2 instances"
}

variable "instance_storage_size" {
  type = "string"
}

variable "master_instance_storage_size" {
  default = 10
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

variable "data_volume_device" {
  type = "string"
  default = "/dev/sdh"
}

variable "data_volume_path" {
  type = "string"
  default = "/srv"
}

variable "elasticsearch_version" {
  type = "string"
  description = "Elasticsearch version to use"
  default = "2.4.5"
}

variable "elasticsearch_http_port" {
  default = 9200
}

variable "elasticsearch_native_port" {
  default = 9300
}

variable "elasticsearch_num_shards" {
  default = 5
}

variable "elasticsearch_num_replicas" {
  default = 0
}

variable "elasticsearch_cluster_name" {
  type = "string"
  description = "Name of Elasticsearch cluster"
}

variable "elasticsearch_master_memory_limit" {
  default = 512
}

variable "elasticsearch_memory_limit" {
  description = "Ammount of memory to allocate for elasticsearch containers"
}

variable "external_masters_addresses" {
  type = "list"
  default = []
}

variable "is_data_nodes_master_eiligible" {
  description = "Wheter we should allow data nodes to be elected as master"
  default = true
}

variable "elasticsearch_master_tasks_count" {
  default = 0
}

variable "elasticsearch_tasks_count" {
  default = 1
}

variable "elasticsearch_master_nodes_count" {
  description = "Number of dedicated master eiligible nodes in cluster. Master nodes doesn't store any data and used only to control the cluster itself"
  default = 0
}

variable "elasticsearch_nodes_count" {
  description = "Number of data nodes in cluster. Data nodes hold the shards and run cluster CRUD operations"
  default = 1
}

variable "extra_iam_roles" {
  type = "list"
  default = []
}