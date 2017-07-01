resource "aws_security_group" "flower-sg" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-flower-access"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "${var.flower_port}"
    to_port = "${var.flower_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  egress {
    from_port = "${var.flower_port}"
    to_port = "${var.flower_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Flower-Access"
  }
}

data "template_file" "flower_node_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    cluster_role = "flower"
    cluster_name = "${var.ecs_cluster_name}"
    instance_group = "${var.ecs_instance_group}"
    host_name = "${lower(var.env_name)}-flower"
    configuration_script = "${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}"
  }
}

resource "aws_instance" "flower_instance" {
  count = "${var.launch_instance}"
  ami = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${element(var.vpc_subnets, 0)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.flower.name}"
  vpc_security_group_ids = ["${concat(var.vpc_security_groups, list(aws_security_group.flower-sg.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"
  user_data = "${data.template_file.flower_node_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Flower"
  }
}

data "aws_route53_zone" "local" {
  zone_id = "${var.vpc_dns_zone_id}"
}

resource "aws_route53_record" "flower_record" {
  count = "${var.launch_instance}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "flower.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${aws_instance.flower_instance.*.private_ip}"]
}