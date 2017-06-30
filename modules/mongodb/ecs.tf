data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "mongod_task" {
  family = "${lower(var.env_name)}-mongod"
  container_definitions = "${data.template_file.mongod_task_config.rendered}"
  volume {
    name = "mongo-data"
    host_path = "${var.data_volume_path}/mongodb-data"
  }
}

resource "aws_ecs_service" "mongod_service" {
  name = "${lower(var.env_name)}-mongod"
  desired_count = "${var.mongod_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.mongod_task.arn}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:group == ${var.ecs_instance_group}"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.mongod_task"]
}

data "template_file" "mongod_task_config" {
  template = "${file("${path.module}/resources/mongodb.json")}"
  vars {
    container_name = "mongod-server"
    mongo_version = "${var.mongodb_version}"
    mongo_container_memory = "${var.mongod_memory_limit}"
    native_transport_port = "${var.mongod_port}"
    volume_name = "mongo-data"
  }
}
