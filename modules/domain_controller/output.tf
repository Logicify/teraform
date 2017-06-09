output "private_ip" {
  value = "${aws_instance.clearos.private_ip}"
}

output "instance_id" {
  value = "${aws_instance.clearos.id}"
}

output "public_ip" {
  value = "${aws_eip.clearos.public_ip}"
}