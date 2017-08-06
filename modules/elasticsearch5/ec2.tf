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


data "template_file" "jvm_config" {
  template = "${file("${path.module}/resources/jvm.options")}"
  vars {
    heap_size = "${var.elasticsearch_memory_limit / 2}"
  }
}

data "template_file" "elasticsearch_config" {
  template = "${file("${path.module}/resources/elasticsearch.yml")}"
  vars {
    cluster_name = "${var.elasticsearch_cluster_name}"
    is_master = "${var.is_data_nodes_master_eiligible == 1 ? "true" : "false"}"
    is_data = "true"
    native_transport_port = "${var.elasticsearch_native_port}"
    http_transport_port = "${var.elasticsearch_http_port}"
    num_shards = "${var.elasticsearch_num_shards}"
    num_replicas = "${var.elasticsearch_num_replicas}"
    min_master_nodes = "${var.elasticsearch_master_nodes_count > 0 ? (var.elasticsearch_master_nodes_count / 2) + 1 : (var.elasticsearch_nodes_count / 2) + 1}"
    master_nodes_addresses = ""
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
    elasticsearch_config = "${base64encode(data.template_file.elasticsearch_config.rendered)}"
    jvm_config = "${base64encode(data.template_file.jvm_config.rendered)}"
    log4j_config = "${base64encode(file("${path.module}/resources/log4j2.properties"))}"
  }
}

resource "aws_instance" "elasticsearch_data_instance" {
  count = "${var.elasticsearch_nodes_count}"
  ami = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
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
  count = "${var.elasticsearch_nodes_count}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.instance_storage_size}"
  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-${var.verbose_name}-Elasticsearch-Data-Volume-Zone${count.index}"
  }
}

resource "aws_volume_attachment" "elasticsearch_data_volume_attachement" {
  count = "${var.elasticsearch_nodes_count}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.elasticsearch_data_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.elasticsearch_data_instance.*.id, count.index)}"
}

data "aws_route53_zone" "local" {
  zone_id = "${var.vpc_dns_zone_id}"
}

resource "aws_route53_record" "elasticsearch_data_record" {
  count = "${var.elasticsearch_nodes_count > 0 ? 1 : 0}"
  zone_id = "${var.vpc_dns_zone_id}"
  name = "elasticsearch.${data.aws_route53_zone.local.name}",
  type = "A"
  ttl = "60"
  records = ["${aws_instance.elasticsearch_data_instance.*.private_ip}"]
}
