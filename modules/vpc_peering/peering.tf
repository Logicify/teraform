resource "aws_vpc_peering_connection" "remote_vpc_link" {
  count = "${var.target_vpc_id != "" ? 1 : 0}"
  peer_vpc_id = "${var.target_vpc_id}"
  vpc_id = "${var.current_vpc_id}"
  auto_accept = "${var.peering_auto_accept}"

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = false
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}: ${var.remote_vpc_name} Link"
  }
}

resource "aws_route" "remote_vpc_routes" {
  count = "${var.target_vpc_id != "" ? length(var.local_route_tables_to_support_link) : 0 }"
  route_table_id = "${element(var.local_route_tables_to_support_link, count.index)}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.remote_vpc_link.id}"
  destination_cidr_block = "${var.target_vpc_network}"
}

resource "aws_security_group" "allow_access_to_remote_vpc" {
  count = "${var.target_vpc_id != "" ? 1 : 0}"
  name = "${lower(var.env_name)}-access-${lower(var.remote_vpc_name)}-lan"
  vpc_id = "${var.current_vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.allow_access_to_remote_vpc_cidrs}"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}: Allow Access to ${var.remote_vpc_name} LAN"
  }
}