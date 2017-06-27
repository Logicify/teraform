resource "aws_security_group" "elasticsearch_sg" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-elasticsearch-access"
  vpc_id = "${var.vpc_id}"

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

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Access"
  }
}

data "template_file" "elasticsearch_master_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    configuration_script = "${base64encode(file("${path.module}/resources/install-unix-tools.sh"))}"
    cluster_name = "${var.ecs_cluster_name}"
    cluster_role = "elasticsearch-master"
    host_name = "${lower(var.verbose_name)}-elasticsearch"
    volume_device = "${var.data_volume_device}"
    volume_path = "${var.data_volume_path}"
  }
}

data "template_file" "elasticsearch_data_cloudconfig" {
  template = "${file("${path.module}/resources/userdata.tpl")}"
  vars {
    configuration_script = "${base64encode(file("${path.module}/resources/install-unix-tools.sh"))}"
    cluster_name = "${var.ecs_cluster_name}"
    cluster_role = "elasticsearch-data"
    host_name = "${lower(var.verbose_name)}-elasticsearch"
    volume_device = "${var.data_volume_device}"
    volume_path = "${var.data_volume_path}"
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
  user_data = "${data.template_file.elasticsearch_master_cloudconfig.rendered}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Master-Zone${count.index}"
  }
}

resource "aws_instance" "elasticsearch_data_instance" {
  count = "${var.data_nodes_count}"
  depends_on = ["aws_ebs_volume.elasticsearch_data_volume"]
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
  user_data = "${data.template_file.elasticsearch_data_cloudconfig.rendered}"
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
    Name = "${var.env_name}-${var.verbose_name}-Elasticseach-Volume-Zone${count.index}"
  }
}

resource "aws_ebs_volume" "elasticsearch_master_volume" {
  count = "${var.master_nodes_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = 10
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticseach-Volume-Zone${count.index}"
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

resource "aws_route53_record" "elasticsearch_master_node_dns_records" {
  count = "${var.master_nodes_count}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "${var.master_nodes_count == 1 ? format("elasticsearch.master.%s", data.aws_route53_zone.local.name) : format("elasticsearch.master%d.%s", count.index, data.aws_route53_zone.local.name)}"
  type = "A"
  ttl = "60"
  records = ["${element(aws_instance.elasticsearch_master_instance.*.private_ip, 0)}"]
}

resource "aws_route53_record" "elasticsearch_data_node_dns_records" {
  count = "${var.data_nodes_count}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "${var.data_nodes_count == 1 ? format("elasticsearch.%s", data.aws_route53_zone.local.name) : format("elasticsearch%d.%s", count.index, data.aws_route53_zone.local.name)}"
  type = "A"
  ttl = "60"
  records = ["${element(aws_instance.elasticsearch_data_instance.*.private_ip, 0)}"]
}