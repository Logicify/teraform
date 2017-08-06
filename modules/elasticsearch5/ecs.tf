data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "elasticsearch_master_task" {
  family = "${lower(var.env_name)}-elasticsearch-master"
  container_definitions = "${data.template_file.elasticsearch_container_config.rendered}"
  volume {
    name = "elasticsearch-data"
    host_path = "${var.data_volume_path}/elasticsearch-data"
  }
  volume {
    name = "elasticsearch-config"
    host_path = "/etc/elasticsearch/config"
  }
}

resource "aws_ecs_task_definition" "elasticsearch_data_task" {
  family = "${lower(var.env_name)}-elasticsearch-data"
  container_definitions = "${data.template_file.elasticsearch_container_config.rendered}"
  volume {
    name = "elasticsearch-data"
    host_path = "${var.data_volume_path}/elasticsearch-data"
  }
  volume {
    name = "elasticsearch-config"
    host_path = "/etc/elasticsearch/config"
  }
}

resource "aws_ecs_service" "elasticsearch_master_service" {
  name = "${lower(var.env_name)}-elasticsearch-master"
  desired_count = "${var.elasticsearch_master_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.elasticsearch_master_task.arn}"
  /* Place only on dedicated instances */
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

data "template_file" "elasticsearch_container_config" {
  template = "${file("${path.module}/resources/elasticsearch.json")}"
  vars {
    elasticsearch_version = "${var.elasticsearch_version}"
    container_name = "elasticsearch-${format("%.6s", uuid())}"
    container_memory = "${var.elasticsearch_memory_limit}"
    native_transport_port = "${var.elasticsearch_native_port}"
    http_transport_port = "${var.elasticsearch_http_port}"
    data_volume = "elasticsearch-data"
    config_volume = "elasticsearch-config"
  }
}