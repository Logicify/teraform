data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "flower_task" {
  family = "${lower(var.env_name)}-flower"
  container_definitions = "${data.template_file.flower_task_config.rendered}"
}

resource "aws_ecs_service" "flower_service" {
  name = "${lower(var.env_name)}-flower"
  desired_count = "${var.flower_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.flower_task.arn}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:group == ${var.ecs_instance_group}"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.flower_task"]
}

data "template_file" "flower_task_config" {
  template = "${file("${path.module}/resources/flower.json")}"
  vars {
    container_name = "flower-monitor"
    flower_version = "${var.flower_version}"
    flower_container_memory = "${var.flower_memory_limit}"
    flower_password = "${var.flower_password}"
    flower_username = "${var.flower_username }"
    flower_broker_url = "${var.flower_broker_url}"
    flower_broker_api_url = "${var.flower_broker_api_url}"
    http_transport_port = "${var.flower_port}"
  }
}
