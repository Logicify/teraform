variable "env_name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
  description = "Id of the VPC to host faclities in"
}

variable "node_vpc_subnets" {
  type = "list"
  description = "VPC subnet ID to start worker nodes in"
}

variable "lb_vpc_subnet" {
  type = "string"
  description = "ID of VPC subnet to start balancer in"
}

variable "selenium_hub_port" {
  default = 4444
  description = "Port where Selenium balancer node (Selenium Hub or GGR) will be listening for connections"
}

variable "selenium_port" {
  default = 4444
  description = "Port where Selenium workers will be listening for connections"
}

variable "web_ui_port" {
  default = 8080
  description = "Port where Selenoid-UI cluster monitor will be listening"
}

variable "web_ui_trusted_networks" {
  type = "list"
  description = "List of network CIDRs to grant access"
}

variable "selenium_hub_trusted_networks" {
  type = "list"
  description = "List of network CIDRs to grant access to selenium hub (ggr)"
}

variable "node_security_groups" {
  type = "list"
  description = "List of IDs of additional security groups to apply to node instances"
  default = []
}

variable "lb_security_groups" {
  type = "list"
  description = "List of IDs of additional security groups to apply to node instances"
  default = []
}

variable "instance_ami" {
  type = "string"
  description = "AMI of ECS optimized Amazon Linux in your region"
}

variable "instance_type_lb" {
  type = "string"
  description = "Instance type for GGR load balancer"
  default = "t2.nano"
}

variable "instance_type_node" {
  type = "string"
  description = "Instance type for worker nodes"
  default = "t2.small"
}

variable "instance_key_name" {
  type = "string"
  description = "SSH key name used to associate with EC2 instances"
}

variable "nodes_asg_desired_capacity" {
  description = "Nodes auto-scaling group desired capacity"
}

variable "nodes_asg_min_size" {
  description = "Nodes auto-scaling group min size"
}

variable "nodes_asg_max_size" {
  description = "Nodes auto-scaling group max size"
}

#====== Aerokube tools config =======

variable "cm_browsers" {
  type = "string"
  description = "Limit configured browsers\\version, see https://aerokube.com/cm/latest/#_example_commands"
  default = "firefox;chrome"
}

variable "cm_last_versions" {
  description = "How many last versions of browsers to keep"
  default = 2
}

variable "cm_enable_vnc" {
  description = "Boolean to enable VNC (default true)"
  default = true
}

variable "cm_selenoid_args" {
  type = "string"
  description = "Additional arguments to pass to selenoid, see https://aerokube.com/selenoid/latest/#_selenoid_cli_flags"
  default = ""
}