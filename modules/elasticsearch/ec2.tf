resource "aws_security_group" "elasticsearch_sg" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-elasticsearch-access"
  vpc_id = "${var.vpc_id}"

  # Elasticsearch native transport protocol
  ingress {
    from_port = "${var.elasticsearch_native_port}"
    to_port = "${var.elasticsearch_native_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch HTTP service
  ingress {
    from_port = "${var.elasticsearch_http_port}"
    to_port = "${var.elasticsearch_http_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch native transport protocol
  egress {
    from_port = "${var.elasticsearch_native_port}"
    to_port = "${var.elasticsearch_native_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  # Elasticsearch HTTP service
  egress {
    from_port = "${var.elasticsearch_http_port}"
    to_port = "${var.elasticsearch_http_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.trusted_networks}"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Access"
  }
}

data "template_file" "master_node_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    cluster_role = "elasticsearch-master"
    cluster_name = "${var.ecs_cluster_name}"
    instance_group = "${var.ecs_instance_group}"
    host_name = "${lower(var.env_name)}-elasticsearch-master"
    volume_path = "${var.data_volume_path}"
    volume_device = "${var.data_volume_device}"
    configuration_script = "${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}"
  }
}

data "template_file" "data_node_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    cluster_role = "elasticsearch-data"
    cluster_name = "${var.ecs_cluster_name}"
    instance_group = "${var.ecs_instance_group}"
    host_name = "${lower(var.env_name)}-elasticsearch-data"
    volume_path = "${var.data_volume_path}"
    volume_device = "${var.data_volume_device}"
    configuration_script = "${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}"
  }
}

resource "aws_instance" "elasticsearch_master_instance" {
  count = "${var.master_nodes_count}"
  ami = "${var.instance_ami}"
  instance_type = "${var.master_instance_type}"
  subnet_id = "${element(var.vpc_subnets, count.index)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.name}"
  vpc_security_group_ids = ["${concat(var.vpc_security_groups, list(aws_security_group.elasticsearch_sg.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"
  user_data = "${data.template_file.master_node_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Master-Zone${count.index}"
  }
}

resource "aws_instance" "elasticsearch_data_instance" {
  count = "${var.data_nodes_count}"
  ami = "${var.instance_ami}"
  instance_type = "${var.data_instance_type}"
  subnet_id = "${element(var.vpc_subnets, count.index)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.name}"
  vpc_security_group_ids = ["${concat(var.vpc_security_groups, list(aws_security_group.elasticsearch_sg.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"
  user_data = "${data.template_file.data_node_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Data-Zone${count.index}"
  }
}

resource "aws_ebs_volume" "elasticsearch_data_volume" {
  count = "${var.data_nodes_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.data_instance_storage_size}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Data-Volume-Zone${count.index}"
  }
}

resource "aws_ebs_volume" "elasticsearch_master_volume" {
  count = "${var.master_nodes_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.master_instance_storage_size}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Master-Volume-Zone${count.index}"
  }
}

resource "aws_volume_attachment" "elasticsearch_data_volume_attachement" {
  count = "${var.data_nodes_count}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.elasticsearch_data_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.elasticsearch_data_instance.*.id, count.index)}"
}

resource "aws_volume_attachment" "elasticsearch_master_volume_attachement" {
  count = "${var.master_nodes_count}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.elasticsearch_master_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.elasticsearch_master_instance.*.id, count.index)}"
}


data "aws_route53_zone" "local" {
  zone_id = "${var.vpc_dns_zone_id}"
}

resource "aws_route53_record" "elasticsearch_master_record" {
  count = "${var.master_nodes_count > 0 ? 1 : 0}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "elasticsearch.master.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${aws_instance.elasticsearch_master_instance.*.private_ip}"]
}

resource "aws_route53_record" "elasticsearch_data_record" {
  count = "${var.data_nodes_count > 0 ? 1 : 0}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "elasticsearch.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${element(aws_instance.elasticsearch_data_instance.*.private_ip, 0)}"]
}
