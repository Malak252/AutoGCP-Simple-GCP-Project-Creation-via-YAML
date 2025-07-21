# modules/compute/variables.tf

# Common Variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

# VM Instance Configuration
variable "vm_instance_count" {
  description = "Number of individual VM instances to create"
  type        = number
  default     = 2
}

variable "vm_machine_type" {
  description = "Machine type for VM instances"
  type        = string
}

variable "vm_image_family" {
  description = "Image family for VM instances"
  type        = string
 
}

variable "vm_image_project" {
  description = "Project containing the image"
  type        = string
 
}

variable "vm_disk_size" {
  description = "Boot disk size for VM instances"
  type        = number
}

variable "vm_disk_type" {
  description = "Boot disk type for VM instances"
  type        = string
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
  description = "SSH public key for accessing instances"
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
  default     = 10
}

variable "mig_cpu_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 0.6
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