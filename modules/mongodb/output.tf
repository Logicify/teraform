output "mongodb_url" {
  value = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_route53_record.mongod_record.name}:${var.mongod_port}/${var.mongodb_database}"
}

output "mongod_instance_ids" {
  value = ["${aws_instance.mongod_instance.*.id}"]
}

output "mongod_instance_ips" {
  value = ["${aws_instance.mongod_instance.*.private_ip}"]
}

output "mongodb_sg_id" {
  value = "${aws_security_group.mongodb-sg.id}"
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.mongodb.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.mongodb_role.id}"
}
