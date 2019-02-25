resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${lower(var.env_name)}-elasticsearch"
  role = "${aws_iam_role.elasticsearch_role.name}"
}

resource "aws_iam_role" "elasticsearch_role" {
  name = "${lower(var.env_name)}-elasticsearch"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_policy.json}"
}

resource "aws_iam_role_policy" "docker_policy" {
  name = "${lower(var.env_name)}-docker-policy"
  role = "${aws_iam_role.elasticsearch_role.id}"
  policy = "${data.aws_iam_policy_document.docker_policy.json}"
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
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "docker_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "extra_iam_roles" {
  count = "${length(var.extra_iam_roles)}"
  policy_arn = "${var.extra_iam_roles[count.index]}"
  role = "${aws_iam_role.elasticsearch_role.id}"
}