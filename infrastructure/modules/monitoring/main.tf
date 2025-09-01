resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-target-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  dimensions = { LoadBalancer = var.alb_arn_suffix }
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = "${var.project_name}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = { AutoScalingGroupName = var.asg_name }
  treat_missing_data = "notBreaching"
}