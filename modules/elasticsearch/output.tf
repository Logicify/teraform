output "private_ips" {
  value = ["${aws_instance.elasticsearch_instance.*.private_ip}"]
}

output "instance_ids" {
  value = ["${aws_instance.elasticsearch_instance.*.id}"]
}

output "elasticsearch_sg_id" {
  value = "${aws_security_group.elasticsearch.id}"
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.elasticsearch.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.elasticsearch_role.id}"
}