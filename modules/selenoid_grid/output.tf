output "lb_instance_id" {
  description = "Instance ID of load balancer"
  value = "${aws_instance.ggr-instance.id}"
}

output "nodes_asg_id" {
  description = "ID of auto-scaling group of worker nodes"
  value = "${aws_autoscaling_group.selenium-grid-asg.id}"
}