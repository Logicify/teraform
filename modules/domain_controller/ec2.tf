resource "aws_security_group" "clearos" {
  vpc_id = "${var.vpc_id}"
  name = "${var.env_name}: Domain controller SG"
  description = "Rules for domain controller"

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    cidr_blocks = [
      "${var.trusted_networks_ssh}"]
    protocol = "tcp"
  }

  # Webpanel
  ingress {
    from_port = 81
    to_port = 81
    cidr_blocks = [
      "${var.trusted_networks_webpanel}"]
    protocol = "tcp"
  }

  # OpenVPN
  ingress {
    from_port = 1194
    to_port = 1194
    cidr_blocks = [
      "${var.trusted_networks_vpn}"]
    protocol = "udp"
  }

  tags {
    Name = "${var.env_name}: Domain controller SG"
  }
}

resource "aws_instance" "clearos" {
  depends_on = [
    "aws_ebs_volume.clearos_data_volume"]
  ami = "${var.centos_ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [
    "${concat(var.default_security_group_ids, list(aws_security_group.clearos.id))}"]
  subnet_id = "${var.target_subnet_id}"
  instance_initiated_shutdown_behavior = "stop"
  key_name = "${var.instance_key_name}"
  disable_api_termination = "${var.enable_termination_protection}"
  user_data = <<USER_DATA_END
#cloud-config
write_files:
- path: /usr/bin/aws-set-hostname
  encoding: b64
  content: ${base64encode(file("${path.module}/resources/aws-set-hostname.sh"))}
  owner: root:root
  permissions: '0755'
- path: /usr/bin/mount-ebs
  encoding: b64
  content: ${base64encode(file("${path.module}/resources/mount-ebs.sh"))}
  owner: root:root
  permissions: '0755'
- path: /usr/bin/centos-to-clearos
  encoding: b64
  content: ${base64encode(file("${path.module}/resources/centos-to-clearos.sh"))}
  owner: root:root
  permissions: '0755'
- path: /etc/profile.d/centos-welcome.sh
  encoding: b64
  content: ${base64encode(file("${path.module}/resources/greatings.sh"))}
  owner: root:root
  permissions: '0755'
runcmd:
  - [ cloud-init-per, once, "set-hostname", "aws-set-hostname", "domain-controller", "-s" ]
USER_DATA_END

  tags {
    Name = "${var.env_name}: Domain Controller"
    Env = "${var.env_name}"
  }
}

data "aws_subnet" "clearos_instance_subnet" {
  id = "${var.target_subnet_id}"
}

resource "aws_ebs_volume" "clearos_data_volume" {
  size = "${var.instance_data_volume_size}"
  availability_zone = "${data.aws_subnet.clearos_instance_subnet.availability_zone}"

  tags {
    Name = "${var.env_name}: Domain controller root volume"
    Env = "${var.env_name}"
  }
}

resource "aws_volume_attachment" "clearos_data_volume" {
  count = 1
  device_name = "${var.instance_data_volume_device_name}"
  force_detach = true
  volume_id = "${aws_ebs_volume.clearos_data_volume.id}"
  instance_id = "${aws_instance.clearos.id}"
}

resource "aws_eip" "clearos" {
  vpc = true
  instance = "${aws_instance.clearos.id}"
}