output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_name : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = length(module.s3) > 0 ? module.s3[0].bucket_arn : null
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups"
  value       = length(module.cloudwatch) > 0 ? module.cloudwatch[0].log_group_names : []
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = length(module.cloudwatch) > 0 ? module.cloudwatch[0].dashboard_url : null
}
