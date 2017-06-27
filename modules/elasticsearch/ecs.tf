resource "aws_ecs_cluster" "elasticsearch_cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "elasticsearch_master_task" {
  family = "${lower(var.env_name)}-elasticsearch-master"
  container_definitions = "${data.template_file.elasticsearch_master_config.rendered}"
  volume {
    name = "elasticseach-data"
    host_path = "${var.data_volume_path}"
  }
}

resource "aws_ecs_task_definition" "elasticsearch_data_task" {
  family = "${lower(var.env_name)}-elasticsearch-data"
  container_definitions = "${data.template_file.elasticsearch_data_config.rendered}"
  volume {
    name = "elasticseach-data"
    host_path = "${var.data_volume_path}"
  }
}

resource "aws_ecs_service" "elasticsearch_master_service" {
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.elasticsearch_master_task"]
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-elasticsearch-master"
  cluster = "${aws_ecs_cluster.elasticsearch_cluster.id}"
  task_definition = "${aws_ecs_task_definition.elasticsearch_master_task.arn}"
  desired_count = "${var.master_nodes_count}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:cluster_role == elasticsearch-master"
  }
}

resource "aws_ecs_service" "elasticsearch_data_service" {
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.elasticsearch_master_task"]
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-elasticsearch-data"
  cluster = "${aws_ecs_cluster.elasticsearch_cluster.id}"
  task_definition = "${aws_ecs_task_definition.elasticsearch_data_task.arn}"
  desired_count = "${var.data_nodes_count}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:cluster_role == elasticsearch-data"
  }
}

data "template_file" "elasticsearch_master_config" {
  template = "${file("${path.module}/../resources/elasticsearch.json")}"
  vars {
    elasticsearch_version = "${var.elasticsearch_version}"
    container_name = "elasticsearch-master"
    container_memory = 512
    native_transport_port = 9300
    http_transport_port = 9200
    cluster_name = "${var.elasticsearch_cluster_name}"
    node_name = "${lower(var.verbose_name)}-elasticsearch-master"
    is_master = "true"
    is_data = "false"
    min_master_nodes = "${var.master_nodes_count == 0 ? (var.master_nodes_count / 2) + 1 : 0}"
    master_nodes_addresses = ""
    heap_size = 256
    volume_name = "elasticseach-data"
  }
}

data "template_file" "elasticsearch_data_config" {
  template = "${file("${path.module}/../resources/elasticsearch.json")}"
  vars {
    elasticsearch_version = "${var.elasticsearch_version}"
    container_name = "elasticsearch-data"
    container_memory = "${var.elasticsearch_memory_limit}"
    native_transport_port = 9300
    http_transport_port = 9200
    cluster_name = "${var.elasticsearch_cluster_name}"
    node_name = "${lower(var.verbose_name)}-elasticsearch-data"
    is_master = "${var.is_data_nodes_master_eiligible == 1 ? "true" : "false"}"
    is_data = "true"
    master_nodes_addresses = "${join(", ", concat(var.external_masters_addresses, aws_route53_record.elasticsearch_master_node_dns_records.*.name))}"
    min_master_nodes = "${(var.master_nodes_count / 2) + 1 }"
    heap_size = "${var.elasticsearch_memory_limit / 2}"
    volume_name = "elasticseach-data"
  }
}