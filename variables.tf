# variables.tf

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "value"
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
  default     = "debian-11"
}

variable "vm_image_project" {
  description = "Project containing the image"
  type        = string
  default     = "debian-cloud"
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

# Compute Module Specific Variables
variable "vm_instance_count" {
  description = "Number of individual VM instances to create"
  type        = number
  default     = 2
}

variable "vm_tags" {
  description = "Network tags for VM instances"
  type        = list(string)
  default     = ["ssh-allowed", "web-server"]
}

variable "vm_enable_external_ip" {
  description = "Enable external IP for individual VM instances"
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "SSH public key for accessing instances (format: ssh-rsa AAAAB3... user@domain)"
  type        = string
  default     = ""
}

# Managed Instance Group Configuration
variable "mig_target_size" {
  description = "Target size for managed instance group"
  type        = number
  default     = 3
}

variable "mig_enable_external_ip" {
  description = "Enable external IP for MIG instances"
  type        = bool
  default     = false
}

variable "mig_max_surge" {
  description = "Maximum number of instances that can be created above target size during updates"
  type        = number
  default     = 1
}

variable "mig_max_unavailable" {
  description = "Maximum number of instances that can be unavailable during updates"
  type        = number
  default     = 1
}

# Autoscaling Configuration
variable "mig_enable_autoscaling" {
  description = "Enable autoscaling for managed instance group"
  type        = bool
  default     = true
}

variable "mig_min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 2
}

variable "mig_max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 3
}

variable "mig_cpu_target" {
  description = "Target CPU utilization for autoscaling (0.1-1.0)"
  type        = number
  default     = 0.6
  validation {
    condition     = var.mig_cpu_target > 0 && var.mig_cpu_target <= 1
    error_message = "CPU target must be between 0.1 and 1.0."
  }
}

variable "mig_cooldown_period" {
  description = "Cooldown period for autoscaling in seconds"
  type        = number
  default     = 60
}

# Regional MIG Configuration
variable "create_regional_mig" {
  description = "Create a regional managed instance group"
  type        = bool
  default     = false
}

variable "regional_mig_target_size" {
  description = "Target size for regional managed instance group"
  type        = number
  default     = 3
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