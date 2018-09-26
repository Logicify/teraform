output "lb_instance_id" {
  description = "Instance ID of load balancer"
  value = "${aws_instance.ggr-instance.id}"
}

output "nodes_asg_id" {
  description = "ID of auto-scaling group of worker nodes"
  value = "${aws_autoscaling_group.selenium-grid-asg.id}"
}

output "lb_private_ip" {
  description = "Private IP address of the load balancer instance"
  value = "${aws_instance.ggr-instance.private_ip}"
}

output "lb_public_ip" {
  description = "Public IP address of the load balancer instance"
  value = "${aws_instance.ggr-instance.public_ip}"
}
