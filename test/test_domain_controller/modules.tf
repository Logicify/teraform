data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet" "default_subnet" {
  vpc_id = "${data.aws_vpc.default_vpc.id}"
  default_for_az = true
  availability_zone = "us-west-1a"
}

data "aws_security_group" "vpc_default" {
  vpc_id = "${data.aws_vpc.default_vpc.id}"
  name = "default"
}


module "domain_controller" {
  source = "../../modules/domain_controller"
  target_subnet_id = "${data.aws_subnet.default_subnet.id}"
  trusted_networks_ssh = "0.0.0.0/0"
  instance_key_name = "aws-logicifydev2"
  env_name = "${var.env_name}"
  trusted_networks_webpanel = "0.0.0.0/0"
  centos_ami = "ami-f5d7f195"
  provisioning_key_path = "${path.root}/keys/aws-logicifydev2.pem"
  default_security_group_ids = ["${data.aws_security_group.vpc_default.id}"]
  enable_termination_protection = "false"
}