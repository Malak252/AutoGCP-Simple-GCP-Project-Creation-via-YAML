variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "multi-cloud-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cloud_provider" {
  description = "Cloud provider to use (aws or gcp)"
  type        = string
  default     = "aws"
  
  validation {
    condition = contains(["aws", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be either 'aws' or 'gcp'."
  }
}

variable "services" {
  description = "List of services to deploy"
  type        = list(string)
  default     = ["storage"]
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "gcp_config" {
  description = "GCP provider configuration"
  type = object({
    project_id       = string
    region           = string
    credentials_file = string
  })
  default = {
    project_id       = "your-project-id"
    region           = "us-central1"
    credentials_file = "credentials.json"
  }
}

variable "aws_config" {
  description = "AWS provider configuration"
  type = object({
    region = string
  })
  default = {
    region = "us-east-1"
  }
}
