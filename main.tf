terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  alias   = "gcp"
  project = var.gcp_config.project_id
  region  = var.gcp_config.region
  credentials = file(var.gcp_config.credentials_file)
}

provider "aws" {
  alias  = "aws"
  region = var.aws_config.region
}

module "gcp_resources" {
  count     = terraform.workspace == "gcp" ? 1 : 0
  source    = "./modules/gcp"
  project_name = var.project_name
  providers = {
    google = google.gcp
  }
}

module "aws_resources" {
  count     = terraform.workspace == "aws" ? 1 : 0
  source    = "./modules/aws"
  project_name = var.project_name
  providers = {
    aws = aws.aws
  }
}

