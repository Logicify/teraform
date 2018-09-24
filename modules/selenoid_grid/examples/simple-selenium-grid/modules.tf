module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "selenium-grid-test-vpc"

  cidr = "10.100.0.0/16"
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.100.1.0/24", "10.100.2.0/24"]
  public_subnets = ["10.100.100.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Env = "${var.env_name}"
  }
  vpc_tags = {

  }
}

resource "aws_security_group" "ssh_sg" {
  name = "ssh_sg"
  description = "Allow ssh connection"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh access"
  }
}

resource "aws_security_group" "all_out_sg" {
  name = "all_out"
  description = "Allow any outgoing traffic"
  vpc_id = "${module.vpc.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "selenium_grid" {
  env_name = "logicify"
  source = "../.."
  vpc_id = "${module.vpc.vpc_id}"
  node_vpc_subnets = "${module.vpc.private_subnets}"
  lb_vpc_subnet = "${element(module.vpc.public_subnets, 0)}"
  instance_ami = "ami-0d7854a15957bfc0d"
  instance_key_name = "kmalyshev"
  node_security_groups = ["${aws_security_group.ssh_sg.id}", "${aws_security_group.all_out_sg.id}"]
  lb_security_groups = ["${aws_security_group.ssh_sg.id}", "${aws_security_group.all_out_sg.id}"]
  selenium_hub_trusted_networks = ["1.1.1.1/32"]  # your office public IP
  web_ui_trusted_networks = ["0.0.0.0/0"]
  nodes_asg_desired_capacity = 1
  nodes_asg_min_size = 0
  nodes_asg_max_size = 5
  cm_browsers = "firefox;chrome"
}

resource "aws_eip" "ggr_eip" {
  instance = "${module.selenium_grid.lb_instance_id}"
}