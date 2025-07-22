# GCP Provider
provider "google" {
  project = var.cloud_provider == "gcp" ? var.gcp_project_id : null
  region  = var.cloud_provider == "gcp" ? var.gcp_region : null
}

provider "google-beta" {
  project = var.cloud_provider == "gcp" ? var.gcp_project_id : null
  region  = var.cloud_provider == "gcp" ? var.gcp_region : null
}

# AWS Provider
provider "aws" {
  region = var.cloud_provider == "aws" ? var.aws_region : "us-east-1"
}
