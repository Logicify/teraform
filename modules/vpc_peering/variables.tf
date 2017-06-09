variable "env_name" {
  type = "string"
}

variable "remote_vpc_name" {
  description = "Name of the remote VPC to be used in resources names. E.g. Production"
  type = "string"
}

variable "current_vpc_id" {
  type = "string"
}

variable "target_vpc_id" {
  type = "string"
}

variable "target_vpc_network" {
  type = "string"
  default = ""
}

variable "peering_auto_accept" {
  type = "string"
  default = true
}

variable "local_route_tables_to_support_link" {
  description = "Traffic from given networks will be routed to remote VPC. Expects the list of route table IDs"
  type = "list"
  default = []
}

variable "vpc_availability_zones" {
  type = "list"
  default = []
}

variable "allow_access_to_remote_vpc_cidrs" {
  type = "list"
}