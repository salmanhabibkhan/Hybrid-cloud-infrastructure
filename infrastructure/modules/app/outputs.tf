output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "ec2_role_name" {
  value = aws_iam_role.ec2_role.name
}