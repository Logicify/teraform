resource "aws_security_group" "graylog-server-sg" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-graylog-access"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch native transport protocol
  ingress {
    from_port = 9300
    to_port = 9300
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch HTTP service
  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound HTTP connections for Graylog UI
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound HTTPS connections for Graylog UI
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound Elasticsearch native protocol connections
  ingress {
    from_port = 9350
    to_port = 9350
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound MongoDB connections
  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound GELF protocol connections via UDP
  ingress {
    from_port = 12201
    to_port = 12210
    protocol = "udp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound GELF protocol connections via TCP
  ingress {
    from_port = 12201
    to_port = 12210
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Inbound Graylog REST API connections
  ingress {
    from_port = 12900
    to_port = 12900
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound HTTP connections for Graylog UI
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound HTTPS connections for Graylog UI
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound Elasticsearch native protocol connections
  egress {
    from_port = 9350
    to_port = 9350
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound MongoDB connections
  egress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound GELF protocol connections via UDP
  egress {
    from_port = 12201
    to_port = 12210
    protocol = "udp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound GELF protocol connections via TCP
  egress {
    from_port = 12201
    to_port = 12210
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  // Outbound Graylog REST API connections
  egress {
    from_port = 12900
    to_port = 12900
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch native transport protocol
  egress {
    from_port = 9300
    to_port = 9300
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch HTTP service
  egress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Graylog-Access"
  }
}

data "template_file" "graylog_node_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    cluster_role = "graylog-server"
    cluster_name = "${var.ecs_cluster_name}"
    instance_group = "${var.ecs_instance_group}"
    host_name = "${lower(var.env_name)}-graylog"
    volume_device = "${var.data_volume_device}"
    volume_path = "${var.data_volume_path}"
    configuration_script = "${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}"
  }
}

resource "aws_instance" "graylog_instance" {
  count = "${var.graylog_nodes_count}"
  ami = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${element(var.vpc_subnets, count.index)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.graylog.name}"
  vpc_security_group_ids = ["${concat(var.vpc_security_groups, list(aws_security_group.graylog-server-sg.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"
  user_data = "${data.template_file.graylog_node_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Graylog-Zone${count.index}"
  }
}

resource "aws_ebs_volume" "graylog_volume" {
  count = "${length(var.graylog_nodes_count)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.instance_storage_size}"

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Graylog-Volume-Zone${count.index}"
  }
}

resource "aws_volume_attachment" "graylog_volume_attachement" {
  count = "${length(var.graylog_nodes_count)}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.graylog_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.graylog_instance.*.id, count.index)}"
}


data "aws_route53_zone" "local" {
  zone_id = "${var.vpc_dns_zone_id}"
}

resource "aws_route53_record" "graylog_record" {
  count = "${var.graylog_nodes_count > 0 ? 1 : 0}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "graylog.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${aws_instance.graylog_instance.*.private_ip}"]
}