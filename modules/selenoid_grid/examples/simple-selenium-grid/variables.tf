variable "env_name" {
  default = "TestEnv"
}

variable "aws_region" {
  default = "us-west-1"
}

variable "aws_credentials_file" {
  default = "./secrets"
  type = "string"
}

variable "aws_credentials_profile" {
  default = "default"
  type = "string"
}