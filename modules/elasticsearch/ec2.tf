resource "aws_instance" "elasticsearch_instance" {
  count = "${var.instances_count}"
  depends_on = ["aws_ebs_volume.elasticsearch_volume"]
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${element(var.vpc_subnets, count.index)}"
  key_name = "${var.instance_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.name}"
  vpc_security_group_ids = ["${concat(var.security_groups, list(aws_security_group.elasticsearch.id))}"]
  associate_public_ip_address = false
  source_dest_check = false
  disable_api_termination = "${var.enable_termination_protection}"
  instance_initiated_shutdown_behavior = "stop"

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}: ${var.verbose_name} Elasticsearch ${count.index}"
  }
  user_data = <<USER_DATA_END
#cloud-config
write_files:
- path: /usr/bin/install-unix-tools
  encoding: b64
  content: ${base64encode(file("${path.module}/../resources/install-unix-tools.sh"))}
  owner: root:root
  permissions: '0755'
- path: /etc/dive-in-docker.conf
  content: elasticsearch
- path: /etc/ecs/ecs.config
  content: |
    ECS_CLUSTER=${var.ecs_cluster_name}
    ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","syslog","journald","gelf","awslogs"]
- path: /etc/sysctl.d/01-elasticsearch.conf
  content: |
    :syslogtag, startswith, "${var.syslog_tag_prefix}" /var/log/${var.docker_log_file_name}
runcmd:
  - [ cloud-init-per, once, "install-unix-tools", "install-unix-tools", "-t", "1.0", "full"]
  - [ cloud-init-per, once, "set-hostname", "aws-set-hostname", "${lower(var.verbose_name)}-elasticsearch-{count.index}", "-s"]
  - [ cloud-init-per, once, "read-custom-syslog", "sysctl", "-p", "/etc/sysctl.d/01-elasticsearch.conf"]
  - [ cloud-init-per, once, "docker-stop", "service", "docker", "stop"]
  - [ cloud-init-per, once, "mount-ebs", "mount-ebs", "${var.data_volume_device}", "${var.data_volume_path}", "0777" ]
  - [ cloud-init-per, once, "docker-start", "service", "docker", "start"]
  - [ cloud-init-per, once, "start-ecs", "start", "ecs"]
USER_DATA_END
}

resource "aws_ebs_volume" "elasticsearch_volume" {
  count = "${length(var.instances_count)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  size = "${var.storage_size}"

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}: ${var.verbose_name} Elasticseach Volume ${count.index}"
  }
}

resource "aws_volume_attachment" "elasticsearch_volume_attachement" {
  count = "${length(var.instances_count)}"
  device_name = "${var.data_volume_device}"
  force_detach = true
  volume_id = "${element(aws_ebs_volume.elasticsearch_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.elasticsearch_instance.*.id, count.index)}"
}


resource "aws_security_group" "elasticsearch" {
  name = "${lower(var.env_name)}-${lower(var.verbose_name)}-elasticsearch"
  vpc_id = "${var.vpc_id}"

  # Elasticsearch native transport protocol
  ingress {
    from_port = 9300
    to_port = 9300
    protocol = "tcp"
    cidr_blocks = ["${var.native_trusted_networks}"]
  }

  # Elasticsearch HTTP service
  ingress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    cidr_blocks = ["${var.http_trusted_networks}"]
  }

  # Elasticsearch native transport protocol
  egress {
    from_port = 9300
    to_port = 9300
    protocol = "tcp"
    cidr_blocks = ["${var.native_trusted_networks}"]
  }

  # Elasticsearch HTTP service
  egress {
    from_port = 9200
    to_port = 9200
    protocol = "tcp"
    cidr_blocks = ["${var.http_trusted_networks}"]
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}: ${var.verbose_name} Elasticsearch"
  }
}
