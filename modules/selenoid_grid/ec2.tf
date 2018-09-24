data "aws_region" "current" {
}

data "aws_subnet" "node_subnet" {
  count = "${length(var.node_vpc_subnets)}"
  id = "${element(var.node_vpc_subnets, count.index)}"
}

data "aws_subnet" "lb_subnet" {
  id = "${var.lb_vpc_subnet}"
}

resource "aws_security_group" "selenium-grid-node-sg" {
  name = "${lower(var.env_name)}-selenium-grid-node-access"
  vpc_id = "${var.vpc_id}"

  # Port for selenium\selenoid instances.
  ingress {
    from_port = "${var.selenium_port}"
    to_port = "${var.selenium_port}"
    protocol = "tcp"
    cidr_blocks = ["${data.aws_subnet.lb_subnet.cidr_block}"]
    description = "Selenium port"
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-selenium-grid-node-access"
  }
}

resource "aws_security_group" "selenium-grid-lb-sg" {
  name = "${lower(var.env_name)}-selenium-grid-loadbalancer-access"
  vpc_id = "${var.vpc_id}"

  # Port for selenium\selenoid proxy.
  ingress {
    from_port = "${var.selenium_hub_port}"
    to_port = "${var.selenium_hub_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.selenium_hub_trusted_networks}"]
  }

  # Port for Selenoid-UI monitoring.
  ingress {
    from_port = "${var.web_ui_port}"
    to_port = "${var.web_ui_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.web_ui_trusted_networks}"]
    description = "Web UI port"
  }

  egress {
    from_port = "${var.selenium_port}"
    to_port = "${var.selenium_port}"
    protocol = "tcp"
    cidr_blocks = ["${data.aws_subnet.node_subnet.*.cidr_block}"]
    description = "Selenium port"
  }

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-selenium-grid-access"
  }
}

data "template_file" "selenoid-init" {
  template = "${file("${path.module}/resources/selenoid_init.d.sh")}"
  vars {
    browsers = "${var.cm_browsers}"
    last_versions = "${var.cm_last_versions}"
    selenium_port = "${var.selenium_port}"
    enable_vnc = "${var.cm_enable_vnc}"
  }
}

data "template_file" "node-user-data" {
  template = <<EOF
#cloud-config
packages:
  - docker
write_files:
  - path: /etc/init.d/selenoid
    owner: root:root
    permissions: '0755'
    encoding: b64
    content: ${base64encode(data.template_file.selenoid-init.rendered)}
runcmd:
  - [ service, docker, start]
  - [ chkconfig, --add, selenoid ]
  - [ service, selenoid, start ]
  - [ docker, pull,2 selenoid/video-recorder ]
EOF
}

resource "aws_launch_template" "selenoid-node-lt" {
  name = "solenoid-node-lt"
  image_id = "${var.instance_ami}"
  instance_type = "${var.instance_type_node}"
  key_name = "${var.instance_key_name}"

  user_data = "${base64encode(data.template_file.node-user-data.rendered)}"

  network_interfaces {
    security_groups = ["${concat(
      list(aws_security_group.selenium-grid-node-sg.id),
      var.node_security_groups
    )}"]
  }

  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "${var.env_name}-selenoid-node"
    }
  }
}

resource "aws_autoscaling_group" "selenium-grid-asg" {
  name = "selenium-grid-asg"
  desired_capacity = "${var.nodes_asg_desired_capacity}"
  max_size = "${var.nodes_asg_max_size}"
  min_size = "${var.nodes_asg_min_size}"
  vpc_zone_identifier = ["${var.node_vpc_subnets}"]

  launch_template {
    id = "${aws_launch_template.selenoid-node-lt.id}"
    version = "$$Latest"
  }
}

data "aws_iam_policy_document" "ggr_nodes_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ec2_assume_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ggr-role" {
  name = "ggr-role"
  description = "Allows GGR to enumerate workers in auto-scaling group"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_policy.json}"
}

resource "aws_iam_role_policy" "ggr-role-policy" {
  name = "ggr-policy"
  policy = "${data.aws_iam_policy_document.ggr_nodes_access_policy.json}"
  role = "${aws_iam_role.ggr-role.id}"
}

resource "aws_iam_instance_profile" "ggr_instance_profile" {
  name = "ggr-instance-profile"
  role = "${aws_iam_role.ggr-role.name}"
}

data "template_file" "ggr-quota-update" {
  template = <<EOF
#!/usr/bin/env bash

OUT="/opt/docker-data/grid-router/quota/ggr-quota.xml"

mkdir -p "$(dirname $OUT)"
/opt/ggr-quota.py --port ${var.selenium_port} ${data.aws_region.current.name} ${aws_autoscaling_group.selenium-grid-asg.name} > "$OUT"

# send SIGHUP to ggr and ggr-ui containers for them to reload quotas
docker kill --signal=HUP $(docker ps | grep ggr | cut -d' ' -f1)
EOF
}

data "template_file" "ggr-quota-update-cron" {
  template = <<EOF
# update selenoid cluster instances every 3 min
*/3 * * * * root /opt/ggr-quota-update.sh
EOF
}

data "template_file" "ggr-docker-compose" {
  template = "${file("${path.module}/resources/docker-compose.yml")}"
  vars {
    hub_port = "${var.selenium_hub_port}"
  }
}

resource "aws_instance" "ggr-instance" {
  ami = "${var.instance_ami}"
  instance_type = "${var.instance_type_lb}"
  subnet_id = "${var.lb_vpc_subnet}"
  key_name = "${var.instance_key_name}"
  vpc_security_group_ids = ["${concat(list(aws_security_group.selenium-grid-lb-sg.id), var.lb_security_groups)}"]
  instance_initiated_shutdown_behavior = "stop"
  iam_instance_profile = "${aws_iam_instance_profile.ggr_instance_profile.name}"

  user_data = <<EOF
#cloud-config
packages:
  - docker
write_files:
  - path: /opt/ggr-quota.py
    owner: root:root
    permissions: '0755'
    encoding: b64
    content: ${base64encode(file("${path.module}/resources/ggr-quota.py"))}
  - path: /opt/ggr-quota-update.sh
    owner: root:root
    permissions: '0755'
    encoding: b64
    content: ${base64encode(data.template_file.ggr-quota-update.rendered)}
  - path: /etc/init.d/ggr-docker-compose
    owner: root:root
    permissions: '0755'
    encoding: b64
    content: ${base64encode(file("${path.module}/resources/ggr-docker-compose_init.d.sh"))}
  - path: /etc/cron.d/ggr-quota-update
    owner: root:root
    permissions: '0644'
    encoding: b64
    content: ${base64encode(data.template_file.ggr-quota-update-cron.rendered)}
  - path: /opt/docker-data/docker-compose.yml
    owner: root:root
    permissions: '0644'
    encoding: b64
    content: ${base64encode(data.template_file.ggr-docker-compose.rendered)}
  - path: /opt/docker-data/grid-router/users.htpasswd
    owner: root:root
    permissions: '0644'
    content: ''
runcmd:
  - [ pip, install, docker-compose ]
  - [ service, docker, start]
  - [ chkconfig, --add, ggr-docker-compose ]
  - [ service, ggr-docker-compose, start ]
EOF

  tags {
    Env = "${var.env_name}"
    Name = "${var.env_name}-selenium-ggr"
  }
}
