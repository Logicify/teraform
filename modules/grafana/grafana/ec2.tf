resource "aws_security_group" "grafana-sg" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-grafana-access"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = "${var.grafana_port}"
    to_port = "${var.grafana_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  egress {
    from_port = "${var.grafana_port}"
    to_port = "${var.grafana_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Grafana-Access"
  }
}

data "template_file" "grafana_node_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    cluster_role = "grafana"
    cluster_name = "${var.ecs_cluster_name}"
    instance_group = "${var.ecs_instance_group}"
    host_name = "${lower(var.env_name)}-grafana"
    volume_path = "${var.data_volume_path}"
    volume_device = "${var.data_volume_device}"
    configuration_script = "${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}"
  }
}

resource "aws_instance" "grafana_instance" {
  count = "${var.grafana_nodes_count}"
  ami = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${element(var.vpc_subnets, count.index)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.grafana.name}"
  vpc_security_group_ids = ["${concat(var.vpc_security_groups, list(aws_security_group.grafana-sg.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"
  user_data = "${data.template_file.grafana_node_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Grafana-Zone${count.index}"
  }
}

resource "aws_ebs_volume" "grafana_volume" {
  count = "${var.grafana_nodes_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.instance_storage_size}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Grafana-Volume-Zone${count.index}"
  }
}

resource "aws_volume_attachment" "grafana_volume_attachement" {
  count = "${var.grafana_nodes_count}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.grafana_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.grafana_instance.*.id, count.index)}"
}


data "aws_route53_zone" "local" {
  zone_id = "${var.vpc_dns_zone_id}"
}

resource "aws_route53_record" "grafana_record" {
  count = "${var.grafana_nodes_count > 0 ? 1 : 0}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "grafana.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${aws_instance.grafana_instance.*.private_ip}"]
}