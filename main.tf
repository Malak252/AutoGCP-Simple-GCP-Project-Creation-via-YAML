data "google_project" "project" {
  project_id = var.project_id
}

# Create a random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for common tags and naming
locals {
  common_tags = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
    created_by  = var.created_by
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common resource names
  vpc_name         = "${local.name_prefix}-vpc"
  subnet_name      = "${local.name_prefix}-subnet"
  gke_cluster_name = "${local.name_prefix}-gke-cluster"
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  name_prefix  = local.name_prefix
  
  # VPC Configuration
  vpc_name                = local.vpc_name
  auto_create_subnetworks = false
  
  # Subnet Configuration
  subnets = [
    {
      name                     = "${local.subnet_name}-main"
      ip_cidr_range           = var.subnet_cidr_main
      region                  = var.region
      private_ip_google_access = true
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = var.subnet_cidr_pods
        },
        {
          range_name    = "services"
          ip_cidr_range = var.subnet_cidr_services
        }
      ]
    }
  ]
  
  # Firewall Rules
  firewall_rules = [
    {
      name      = "allow-ssh"
      direction = "INGRESS"
      priority  = 1000
      ranges    = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
      target_tags = ["ssh-allowed"]
    },
    {
      name      = "allow-http-https"
      direction = "INGRESS"
      priority  = 1000
      ranges    = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
      target_tags = ["web-server"]
    }
  ]
  
  common_tags = local.common_tags
}