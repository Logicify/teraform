output "remote_vpc_connection" {
  value = "${aws_vpc_peering_connection.remote_vpc_link.id}"
}

output "remote_network_access_sg_id" {
  value = "${aws_security_group.allow_access_to_remote_vpc.id}"
}