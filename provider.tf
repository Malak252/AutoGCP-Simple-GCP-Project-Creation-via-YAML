
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.84"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.84"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure Google provider (only when using GCP)
provider "google" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_config.project_id
  region  = var.gcp_config.region
}

provider "google-beta" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_config.project_id
  region  = var.gcp_config.region
}

# Configure AWS provider (only when using AWS)
provider "aws" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  region = var.aws_config.region
  
  default_tags {
    tags = merge(var.labels, {
      Environment   = var.environment
      Project      = var.project_name
      ManagedBy    = "terraform"
      CloudProvider = "aws"
    })
  }
}
