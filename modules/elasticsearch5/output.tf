output "elasticsearch_http_address" {
  value = "${format("http://%s:%s", aws_route53_record.elasticsearch_data_record.name, var.elasticsearch_http_port)}"
}

output "elasticsearch_native_address" {
  value = "${format("%s:%s", aws_route53_record.elasticsearch_data_record.name, var.elasticsearch_native_port)}"
}
output "instance_ids" {
  value = ["${aws_instance.elasticsearch_data_instance.*.id}"]
}

output "instance_ips" {
  value = ["${aws_instance.elasticsearch_data_instance.*.private_ip}"]
}

output "elasticsearch_sg_id" {
  value = "${aws_security_group.elasticsearch_sg.id}"
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.elasticsearch.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.elasticsearch_role.id}"
}
