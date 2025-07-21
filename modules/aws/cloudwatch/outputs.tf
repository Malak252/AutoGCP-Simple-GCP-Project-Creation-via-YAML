output "log_group_names" {
  description = "Names of created CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.this : lg.name]
}

output "log_group_arns" {
  description = "ARNs of created CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.this : lg.arn]
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.dashboard_config != null ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.this[0].dashboard_name}" : null
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.dashboard_config != null ? aws_cloudwatch_dashboard.this[0].dashboard_name : null
}

output "metric_alarm_arns" {
  description = "ARNs of created CloudWatch metric alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.this : alarm.arn]
}

output "metric_alarm_names" {
  description = "Names of created CloudWatch metric alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.this : alarm.alarm_name]
}

output "sns_topic_arns" {
  description = "ARNs of SNS topics created for alarms"
  value       = [for topic in aws_sns_topic.alarm_notifications : topic.arn]
}
