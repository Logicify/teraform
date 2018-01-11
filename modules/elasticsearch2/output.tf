output "elasticsearch_http_address" {
  value = "${var.elasticsearch_master_nodes_count > 0  ? format("http://%s:%s", element(aws_route53_record.elasticsearch_master_record.*.name,0), var.elasticsearch_http_port) : format("http://%s:%s", element(aws_route53_record.elasticsearch_master_record.*.name,0), var.elasticsearch_http_port)}"
}

output "elasticsearch_native_address" {
  value = "${var.elasticsearch_master_nodes_count > 0  ? format("%s:%s", element(aws_route53_record.elasticsearch_master_record.*.name,0), var.elasticsearch_native_port) : format("%s:%s", element(aws_route53_record.elasticsearch_master_record.*.name,0), var.elasticsearch_native_port)}"
}

output "master_instance_ids" {
  value = ["${aws_instance.elasticsearch_master_instance.*.id}"]
}


output "master_instance_ips" {
  value = ["${aws_instance.elasticsearch_master_instance.*.private_ip}"]
}

output "data_instance_ids" {
  value = ["${aws_instance.elasticsearch_data_instance.*.id}"]
}


output "data_instance_ips" {
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
