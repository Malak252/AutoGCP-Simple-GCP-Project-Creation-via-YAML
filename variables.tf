# Variable definitions for multi-cloud Terraform deployment

variable "cloud_provider" {
  description = "Cloud provider to use (gcp or aws)"
  type        = string
  validation {
    condition     = contains(["gcp", "aws"], var.cloud_provider)
    error_message = "Cloud provider must be either 'gcp' or 'aws'."
  }
}

variable "services" {
  description = "List of services to deploy"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for service in var.services :
      contains(["kubernetes", "cloud_function", "lambda", "storage", "monitoring"], service)
    ])
    error_message = "Services must be one of: kubernetes, cloud_function, lambda, storage, monitoring."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "labels" {
  description = "Common labels/tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# GCP Configuration
variable "gcp_config" {
  description = "GCP-specific configuration"
  type = object({
    project_id      = string
    organization_id = optional(string)
    billing_account = optional(string)
    region         = string
    
    kubernetes = optional(object({
      cluster_name = string
      node_count   = number
      machine_type = string
    }))
    
    cloud_function = optional(object({
      function_name  = string
      runtime        = string
      entry_point    = string
      source_archive = string
    }))
    
    storage = optional(object({
      bucket_name   = string
      storage_class = string
    }))
    
    monitoring = optional(object({
      notification_channel = string
    }))
  })
  default = {
    project_id = ""
    region     = "us-central1"
  }
}

# AWS Configuration
variable "aws_config" {
  description = "AWS-specific configuration"
  type = object({
    region = string
    
    eks = optional(object({
      cluster_name     = string
      node_group_name  = string
      instance_types   = list(string)
      desired_capacity = number
      max_capacity     = number
      min_capacity     = number
    }))
    
    lambda = optional(object({
      function_name = string
      runtime       = string
      handler       = string
      source_file   = string
    }))
    
    s3 = optional(object({
      bucket_name = string
    }))
    
    cloudwatch = optional(object({
      log_group = string
    }))
  })
  default = {
    region = "us-west-2"
  }
}
