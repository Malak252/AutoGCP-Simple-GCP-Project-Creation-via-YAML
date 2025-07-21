# Variables for GCP Monitoring module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "notification_channel" {
  description = "Email address for notifications"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
