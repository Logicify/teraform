data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "graylog_task" {
  family = "${lower(var.env_name)}-graylog"
  container_definitions = "${data.template_file.graylog_server_config.rendered}"
  volume {
    name = "graylog-data"
    host_path = "${var.data_volume_path}/graylog-data"
  }
}

resource "aws_ecs_service" "graylog_service" {
  name = "${lower(var.env_name)}-graylog"
  desired_count = "${var.graylog_tasks_count}"
  cluster = "${data.aws_ecs_cluster.ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.graylog_task.arn}"
  placement_constraints {
    type = "memberOf"
    expression = "attribute:group == ${var.ecs_instance_group}"
  }
  depends_on = ["aws_iam_role_policy.docker_policy", "aws_ecs_task_definition.graylog_task"]
}

data "template_file" "graylog_server_config" {
  template = "${file("${path.module}/resources/graylog.json")}"
  vars {
    graylog_version = "${var.graylog_version}"
    container_name = "graylog-server"
    container_memory = "${var.graylog_memory_limit}"
    graylog_password_secret = "${var.graylog_password_secret}"
    graylog_admin_password_sha2 = "${var.graylog_admin_sha2}"
    smtp_host = "${var.smtp_host}"
    smtp_port = "${var.smtp_port}"
    smtp_username  = "${var.smtp_user}"
    smtp_password = "${var.smtp_password}"
    smtp_use_tls = "${var.smtp_use_tls}"
    email_from = "${var.graylog_sent_email_from}"
    graylog_url = "${var.graylog_url}"
    mongodb_url = "${var.mongodb_url}"
    elasticsearch_url = "${var.elasticsearch_url}"
    graylog_is_master = "${var.graylog_is_master == 1 ? "true" : "false"}"
    graylog_rest_transport_url = "${var.graylog_url}/api"
    elasticsearch_shards = "${var.elasticsearch_num_shards}"
    elasticsearch_replicas = "${var.elasticsearch_num_replicas}"
    elasticsearch_cluster_name = "${var.elasticsearch_cluster_name}"
    volume_name = "graylog-data"
  }
}
