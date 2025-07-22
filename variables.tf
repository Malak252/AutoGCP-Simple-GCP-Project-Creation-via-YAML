variable "project_name" {
  description = "Name of the project"
  type        = string
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

