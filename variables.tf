variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "terraform-gcp"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "created_by" {
  description = "Who created this infrastructure"
  type        = string
  default     = "terraform"
}

# Network Configuration
variable "subnet_cidr_main" {
  description = "CIDR range for the main subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_pods" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr_services" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

# VM Configuration
variable "vm_machine_type" {
  description = "Machine type for VM instances"
  type        = string
  default     = "e2-medium"
}

variable "vm_image_family" {
  description = "Image family for VM instances"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "vm_image_project" {
  description = "Project containing the image"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "vm_disk_size" {
  description = "Boot disk size for VM instances"
  type        = number
  default     = 20
}

variable "vm_disk_type" {
  description = "Boot disk type for VM instances"
  type        = string
  default     = "pd-standard"
}

# Database Configuration
variable "database_version" {
  description = "Database version"
  type        = string
  default     = "MYSQL_8_0"
}

variable "database_tier" {
  description = "Database tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_disk_size" {
  description = "Database disk size"
  type        = number
  default     = 10
}

variable "database_disk_type" {
  description = "Database disk type"
  type        = string
  default     = "PD_SSD"
}

variable "database_backup_enabled" {
  description = "Enable database backups"
  type        = bool
  default     = true
}

variable "database_maintenance_window" {
  description = "Database maintenance window"
  type = object({
    hour         = number
    day          = number
    update_track = string
  })
  default = {
    hour         = 3
    day          = 1
    update_track = "stable"
  }
}

variable "database_authorized_networks" {
  description = "Authorized networks for database access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "database_user_name" {
  description = "Database user name"
  type        = string
  default     = "appuser"
}

# GKE Configuration
variable "gke_kubernetes_version" {
  description = "Kubernetes version for GKE cluster"
  type        = string
  default     = "1.27"
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "gke_node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes in the GKE cluster"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes in the GKE cluster"
  type        = number
  default     = 10
}

variable "gke_disk_size" {
  description = "Disk size for GKE nodes"
  type        = number
  default     = 20
}

variable "gke_disk_type" {
  description = "Disk type for GKE nodes"
  type        = string
  default     = "pd-standard"
}

variable "gke_image_type" {
  description = "Image type for GKE nodes"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "gke_preemptible" {
  description = "Use preemptible nodes"
  type        = bool
  default     = true
}
