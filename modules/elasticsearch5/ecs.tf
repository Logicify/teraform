data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "elasticsearch_master_task" {
  family = "${lower(var.env_name)}-elasticsearch-master"
  container_definitions = "${data.template_file.elasticsearch_master_config.rendered}"
  volume {
    name = "elasticsearch-data"
    host_path = "${var.data_volume_path}/elasticsearch-data"
  }
}

resource "aws_ecs_task_definition" "elasticsearch_data_task" {
  family = "${lower(var.env_name)}-elasticsearch-data"
  container_definitions = "${data.template_file.elasticsearch_data_config.rendered}"
  volume {
    name = "elasticsearch-data"
    host_path = "${var.data_volume_path}/elasticsearch-data"
  }
}

resource "aws_ecs_service" "elasticsearch_master_service" {
  name = "${lower(var.env_name)}-elasticsearch-master"
  desired_count = "${var.elasticsearch_master_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.elasticsearch_master_task.arn}"
  /* Place only of dedicated instances */
  placement_constraints {
    type = "memberOf"
    expression = "attribute:cluster_role == elasticsearch-master"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.elasticsearch_master_task"]
}

resource "aws_ecs_service" "elasticsearch_data_service" {
  name = "${lower(var.env_name)}-elasticsearch-data"
  desired_count = "${var.elasticsearch_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.elasticsearch_data_task.arn}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:group == ${var.ecs_instance_group}"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.elasticsearch_master_task"]
}

data "template_file" "elasticsearch_master_config" {
  template = "${file("${path.module}/resources/elasticsearch.json")}"
  vars {
    elasticsearch_version = "${var.elasticsearch_version}"
    container_name = "elasticsearch-master"
    container_memory = "${var.elasticsearch_master_memory_limit}"
    native_transport_port = "${var.elasticsearch_native_port}"
    http_transport_port = "${var.elasticsearch_http_port}"
    cluster_name = "${var.elasticsearch_cluster_name}"
    node_name = "${lower(var.verbose_name)}-elasticsearch-master-${format("%.7s", uuid())}"
    is_master = "true"
    is_data = "false"
    num_shards = "${var.elasticsearch_num_shards}"
    num_replicas = "${var.elasticsearch_num_replicas}"
    heap_size = "${var.elasticsearch_memory_limit / 2}"
    volume_name = "elasticsearch-data"
    min_master_nodes = "${(var.elasticsearch_master_nodes_count / 2) + 1 }"
  }
}

data "template_file" "elasticsearch_data_config" {
  template = "${file("${path.module}/resources/elasticsearch.json")}"
  vars {
    elasticsearch_version = "${var.elasticsearch_version}"
    container_name = "elasticsearch-data"
    container_memory = "${var.elasticsearch_memory_limit}"
    native_transport_port = "${var.elasticsearch_native_port}"
    http_transport_port = "${var.elasticsearch_http_port}"
    cluster_name = "${var.elasticsearch_cluster_name}"
    node_name = "${lower(var.verbose_name)}-elasticsearch-data-${format("%.7s", uuid())}"
    is_master = "${var.is_data_nodes_master_eiligible == 1 ? "true" : "false"}"
    is_data = "true"
    num_shards = "${var.elasticsearch_num_shards}"
    num_replicas = "${var.elasticsearch_num_replicas}"
    heap_size = "${var.elasticsearch_memory_limit / 2}"
    volume_name = "elasticsearch-data"
    min_master_nodes = "${(var.elasticsearch_master_nodes_count / 2) + 1 }"
    master_nodes_addresses = "${join(", ", concat(var.external_masters_addresses, formatlist("$s:%s", aws_route53_record.elasticsearch_master_record.*.name, var.elasticsearch_native_port)))}"
  }
}