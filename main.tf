terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure Google provider
provider "google" {
  alias       = "gcp"
  project     = var.gcp_config.project_id
  region      = var.gcp_config.region
  credentials = file(var.gcp_config.credentials_file)
}

provider "google-beta" {
  alias       = "gcp_beta"
  project     = var.gcp_config.project_id
  region      = var.gcp_config.region
  credentials = file(var.gcp_config.credentials_file)
}

# Configure AWS provider
provider "aws" {
  alias  = "aws"
  region = var.aws_config.region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project      = var.project_name
      ManagedBy    = "terraform"
    }
  }
}

# Conditional module loading based on workspace
module "gcp_resources" {
  count     = terraform.workspace == "gcp" ? 1 : 0
  source    = "./modules/gcp"
  
  project_name = var.project_name
  environment  = var.environment
  
  providers = {
    google = google.gcp
  }
}

module "aws_resources" {
  count     = terraform.workspace == "aws" ? 1 : 0
  source    = "./modules/aws"
  
  project_name = var.project_name
  environment  = var.environment
  
  providers = {
    aws = aws.aws
  }
}
