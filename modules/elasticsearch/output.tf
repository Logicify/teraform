output "private_ips" {
  value = ["${aws_instance.elasticsearch_data_instance.*.private_ip}"]
}

output "elasticseacrch_master_addresses" {
  value = "${formatlist("%s:%s", aws_route53_record.elasticsearch_master_node_dns_records.*.name)}"
}

output "elasticseacrch_node_addresses" {
  value = "${formatlist("%s:%s", aws_route53_record.elasticsearch_data_node_dns_records.*.name)}"
}

output "instance_ids" {
  value = ["${aws_instance.elasticsearch_data_instance.*.id}"]
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
