# Main Terraform configuration - Conditionally provisions resources based on YAML input

terraform {
  required_version = ">= 1.0"
}

# Conditionally create GCP resources based on cloud provider selection
module "gcp_kubernetes" {
  count  = var.cloud_provider == "gcp" && contains(var.services, "kubernetes") ? 1 : 0
  source = "./modules/gcp/kubernetes"

  project_id           = var.gcp_config.project_id
  region              = var.gcp_config.region
  cluster_name        = var.gcp_config.kubernetes.cluster_name
  node_count          = var.gcp_config.kubernetes.node_count
  machine_type        = var.gcp_config.kubernetes.machine_type
  labels              = var.labels
}

module "gcp_cloud_function" {
  count  = var.cloud_provider == "gcp" && contains(var.services, "cloud_function") ? 1 : 0
  source = "./modules/gcp/cloud_function"

  project_id      = var.gcp_config.project_id
  region         = var.gcp_config.region
  function_name  = var.gcp_config.cloud_function.function_name
  runtime        = var.gcp_config.cloud_function.runtime
  entry_point    = var.gcp_config.cloud_function.entry_point
  source_archive = var.gcp_config.cloud_function.source_archive
  labels         = var.labels
}

module "gcp_storage" {
  count  = var.cloud_provider == "gcp" && contains(var.services, "storage") ? 1 : 0
  source = "./modules/gcp/storage"

  project_id    = var.gcp_config.project_id
  bucket_name   = var.gcp_config.storage.bucket_name
  location      = var.gcp_config.region
  storage_class = var.gcp_config.storage.storage_class
  labels        = var.labels
}

module "gcp_monitoring" {
  count  = var.cloud_provider == "gcp" && contains(var.services, "monitoring") ? 1 : 0
  source = "./modules/gcp/monitoring"

  project_id           = var.gcp_config.project_id
  notification_channel = var.gcp_config.monitoring.notification_channel
  labels              = var.labels
}

# Conditionally create AWS resources based on cloud provider selection
module "aws_eks" {
  count  = var.cloud_provider == "aws" && contains(var.services, "kubernetes") ? 1 : 0
  source = "./modules/aws/eks"

  region            = var.aws_config.region
  cluster_name      = var.aws_config.eks.cluster_name
  node_group_name   = var.aws_config.eks.node_group_name
  instance_types    = var.aws_config.eks.instance_types
  desired_capacity  = var.aws_config.eks.desired_capacity
  max_capacity      = var.aws_config.eks.max_capacity
  min_capacity      = var.aws_config.eks.min_capacity
  tags              = var.labels
}

module "aws_lambda" {
  count  = var.cloud_provider == "aws" && contains(var.services, "lambda") ? 1 : 0
  source = "./modules/aws/lambda"

  region        = var.aws_config.region
  function_name = var.aws_config.lambda.function_name
  runtime       = var.aws_config.lambda.runtime
  handler       = var.aws_config.lambda.handler
  source_file   = var.aws_config.lambda.source_file
  tags          = var.labels
}

module "aws_s3" {
  count  = var.cloud_provider == "aws" && contains(var.services, "storage") ? 1 : 0
  source = "./modules/aws/s3"

  region      = var.aws_config.region
  bucket_name = var.aws_config.s3.bucket_name
  tags        = var.labels
}

module "aws_cloudwatch" {
  count  = var.cloud_provider == "aws" && contains(var.services, "monitoring") ? 1 : 0
  source = "./modules/aws/cloudwatch"
  
  workspace    = terraform.workspace
  project_name = var.project_name
  tags         = var.labels
  
  log_groups = [
    {
      name              = var.aws_config.cloudwatch.log_group
      retention_days    = 14
      skip_destroy      = false
    }
  ]
}
