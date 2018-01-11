output "grafana_url" {
  value = "http://${element(aws_route53_record.grafana_record.*.name, 0)}:${var.grafana_port}"
}

output "grafana_instance_ids" {
  value = ["${aws_instance.grafana_instance.*.id}"]
}

output "grafana_instance_ips" {
  value = ["${aws_instance.grafana_instance.*.private_ip}"]
}

output "grafana_sg_id" {
  value = "${aws_security_group.grafana-sg.id}"
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.grafana.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.grafana_role.id}"
}
