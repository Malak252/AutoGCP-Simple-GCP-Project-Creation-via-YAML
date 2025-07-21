# Output values to display information after deployment

# GCP Outputs
output "gcp_kubernetes_cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.cloud_provider == "gcp" && contains(var.services, "kubernetes") ? module.gcp_kubernetes[0].cluster_name : null
}

output "gcp_kubernetes_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.cloud_provider == "gcp" && contains(var.services, "kubernetes") ? module.gcp_kubernetes[0].cluster_endpoint : null
  sensitive   = true
}

output "gcp_cloud_function_url" {
  description = "URL of the Cloud Function"
  value       = var.cloud_provider == "gcp" && contains(var.services, "cloud_function") ? module.gcp_cloud_function[0].function_url : null
}

output "gcp_storage_bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = var.cloud_provider == "gcp" && contains(var.services, "storage") ? module.gcp_storage[0].bucket_url : null
}

# AWS Outputs
output "aws_eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.cloud_provider == "aws" && contains(var.services, "kubernetes") ? module.aws_eks[0].cluster_name : null
}

output "aws_eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.cloud_provider == "aws" && contains(var.services, "kubernetes") ? module.aws_eks[0].cluster_endpoint : null
  sensitive   = true
}

output "aws_lambda_function_name" {
  description = "Name of the Lambda function"
  value       = var.cloud_provider == "aws" && contains(var.services, "lambda") ? module.aws_lambda[0].function_name : null
}

output "aws_s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.cloud_provider == "aws" && contains(var.services, "storage") ? module.aws_s3[0].bucket_name : null
}

# General Outputs
output "cloud_provider" {
  description = "Cloud provider used"
  value       = var.cloud_provider
}

output "deployed_services" {
  description = "List of deployed services"
  value       = var.services
}

output "environment" {
  description = "Environment"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}
