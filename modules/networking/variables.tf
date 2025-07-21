variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
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
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "Whether to create subnetworks automatically"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network routing mode"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}

# Subnet Configuration
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                     = string
    ip_cidr_range           = string
    region                  = string
    private_ip_google_access = bool
    secondary_ip_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
    flow_logs_enabled = optional(bool, false)
    flow_logs_config = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling       = optional(number, 0.5)
      metadata           = optional(string, "INCLUDE_ALL_METADATA")
    }), {})
  }))
  default = []
}

# NAT Configuration
variable "enable_nat" {
  description = "Enable Cloud NAT"
  type        = bool
  default     = true
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option"
  type        = string
  default     = "AUTO_ONLY"
  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be either AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_ip_count" {
  description = "Number of NAT IPs to allocate (only used with MANUAL_ONLY)"
  type        = number
  default     = 1
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "Source subnetwork IP ranges to NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "nat_subnetworks" {
  description = "List of subnetworks for NAT"
  type = list(object({
    name                    = string
    source_ip_ranges_to_nat = list(string)
  }))
  default = []
}

variable "nat_log_config" {
  description = "NAT logging configuration"
  type = object({
    enable = bool
    filter = string
  })
  default = {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

# Firewall Configuration
variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    name                    = string
    description            = optional(string, "")
    direction              = string
    priority               = optional(number, 1000)
    ranges                 = optional(list(string), [])
    source_tags            = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    target_tags            = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  default = []
}

