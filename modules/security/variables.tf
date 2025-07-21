variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "secret_name" {
  type        = string
  description = "Name of the secret"
}

variable "secret_value" {
  type        = string
  description = "The actual secret value"
  sensitive   = true
}

variable "service_account_email" {
  type        = string
  description = "Service account to grant access to secret"
}
