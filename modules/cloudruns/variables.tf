variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Region for Cloud Run"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "image" {
  type        = string
  description = "Docker image (Docker Hub or GCR)"
  #default = "sha256:0332496bf24cac3ae5967b4c170f0e513f671d81b00e4d929fae3bcc04913590/shahdsamir19:latest"
}

variable "container_port" {
  type        = number
  default     = 3000
  description = "Container port to expose"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the container"
}

variable "resource_limits" {
  type = map(string)
  default = {
    memory = "512Mi"
    cpu    = "1"
  }
  description = "Resource limits (memory and CPU)"
}

variable "allow_unauthenticated" {
  type        = bool
  default     = true
  description = "Whether to allow unauthenticated (public) access"
}

variable "annotations" {
  type        = map(string)
  default     = {}
  description = "Annotations for the Cloud Run service"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to the service"
}
variable "ingress_type" {
  description = "Ingress type for Cloud Run (all, internal-only, internal-and-cloud-load-balancing)"
  type        = string
  default     = "all"
}