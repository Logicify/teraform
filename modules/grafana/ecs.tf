data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "grafana_task" {
  family = "${lower(var.env_name)}-grafana"
  container_definitions = "${data.template_file.grafana_task_config.rendered}"
  volume {
    name = "grafana-data"
    host_path = "${var.data_volume_path}/grafana-data"
  }
}

resource "aws_ecs_service" "grafana_service" {
  name = "${lower(var.env_name)}-grafana"
  desired_count = "${var.grafana_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.grafana_task.arn}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:group == ${var.ecs_instance_group}"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.grafana_task"]
}

data "template_file" "grafana_task_config" {
  template = "${file("${path.module}/resources/grafana.json")}"
  vars {
    container_name = "grafana-server"
    grafana_version = "${var.grafana_version}"
    grafana_container_memory = "${var.grafana_memory_limit}"
    grafana_password = "${var.grafana_admin_password}"
    grafana_url = "${var.grafana_url}"
    http_transport_port = "${var.grafana_port}"
    volume_name = "grafana-data"
  }
}
