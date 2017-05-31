resource "aws_security_group" "rabbitmq" {
  name = "${lower(var.env_name)}-rabbitmq"
  description = "Rabbitmq access rules"
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol = "tcp"
    from_port = "15672"
    to_port = "15672"
    cidr_blocks = ["${var.trusted_networks_control_panel}"]
  }

  ingress {
    protocol = "tcp"
    from_port = "5672"
    to_port = "5672"
    cidr_blocks = ["${var.trusted_networks_amqp}"]
  }

  tags {
    "Name" = "${var.env_name}: RabbitMQ"
    "Env" = "${var.env_name}"
  }
}

resource "aws_instance" "rabitmq" {
  ami = "${var.ami}"
  count = 1
  key_name = "${var.instance_key_name}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.target_subnet_id}"
  vpc_security_group_ids = [
    "${concat(var.default_security_group_ids, list(aws_security_group.rabbitmq.id))}"]
  disable_api_termination = "${var.enable_termination_protection}"
  user_data = <<USER_DATA_END
#cloud-config
write_files:
- path: /usr/bin/aws-set-hostname
  encoding: b64
  content: ${base64encode(file("${path.module}/../resources/aws-set-hostname.sh"))}
  owner: root:root
  permissions: '0755'
- path: /etc/dive-in-docker.conf
  content: rabbitmq
runcmd:
  - [ cloud-init-per, once, "set-hostname", "aws-set-hostname", "rabbitmq", "-s"]
USER_DATA_END

  tags {
    "Name" = "${var.env_name}: RabbitMQ"
    "Env" = "${var.env_name}"
  }
}