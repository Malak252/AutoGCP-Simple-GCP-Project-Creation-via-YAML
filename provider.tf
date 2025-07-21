
provider "google" {
  alias       = "gcp"
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = file(var.gcp_credentials_path)
}

provider "aws" {
  alias      = "aws"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "gcp_resources" {
  source = "./modules/gcp"
  count  = var.gcp_enabled ? 1 : 0

  providers = {
    google = google.gcp
  }

  project_id = var.gcp_project
  region     = var.gcp_region
}

module "aws_resources" {
  source = "./modules/aws"
  count  = var.aws_enabled ? 1 : 0

  providers = {
    aws = aws.aws
  }

  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

