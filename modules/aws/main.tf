# AWS Main Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# S3 Module
module "s3" {
  count = contains(var.services, "storage") ? 1 : 0
  source = "./s3"
  
  region      = var.aws_config.region
  bucket_name = "${var.project_name}-${var.environment}-storage"
  
  tags = merge(var.labels, {
    Environment = var.environment
    Project     = var.project_name
  })
  
  providers = {
    aws = aws
  }
}

# CloudWatch Module
module "cloudwatch" {
  count = contains(var.services, "monitoring") ? 1 : 0
  source = "./cloudwatch"
  
  workspace    = terraform.workspace
  project_name = var.project_name
  
  # Example log groups
  log_groups = [
    {
      name           = "/aws/lambda/${var.project_name}"
      retention_days = 14
    }
  ]
  
  # Example metric alarms
  metric_alarms = [
    {
      name                = "high-error-rate"
      metric_name         = "Errors"
      namespace          = "AWS/Lambda"
      statistic          = "Sum"
      threshold          = 10
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods = 2
      period             = 300
      alarm_description  = "High error rate detected"
    }
  ]
  
  tags = merge(var.labels, {
    Environment = var.environment
    Project     = var.project_name
  })
  
  providers = {
    aws = aws
  }
}
