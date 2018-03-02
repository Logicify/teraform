output "flower_url" {
  value = "http://${element(concat(aws_route53_record.flower_record.*.name,list("")), 0)}:${var.flower_port}"
}

output "flower_instance_id" {
  value = "${element(concat(aws_instance.flower_instance.*.id,list("")), 0)}"
}

output "flower_instance_ip" {
  value = "${element(concat(aws_instance.flower_instance.*.private_ip,list("")), 0)}"
}

output "flower_sg_id" {
  value = "${aws_security_group.flower-sg.id}"
}

output "instance_profile_id" {
  value = "${aws_iam_instance_profile.flower.id}"
}

output "iam_role_id" {
  value = "${aws_iam_role.flower_role.id}"
}
