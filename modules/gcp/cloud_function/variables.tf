# Variables for GCP Cloud Function module

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
}

variable "runtime" {
  description = "Runtime for the function"
  type        = string
  default     = "python39"
}

variable "entry_point" {
  description = "Entry point for the function"
  type        = string
  default     = "main"
}

variable "source_archive" {
  description = "Path to the source archive zip file"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
