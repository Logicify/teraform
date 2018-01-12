output "graylog_address" {
  value = "http://${element(concat(aws_route53_record.graylog_record.*.name,list("")), 0)}"
}

output "graylog_instance_ids" {
  value = ["${aws_instance.graylog_instance.*.id}"]
}

output "graylog_instance_ips" {
  value = ["${aws_instance.graylog_instance.*.private_ip}"]
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.graylog.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.graylog_role.id}"
}