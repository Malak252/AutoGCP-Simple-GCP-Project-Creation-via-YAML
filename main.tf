# main.tf

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
  source      = "./modules/networking"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  name_prefix = local.name_prefix
  
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

# Compute Module
module "compute" {
  source      = "./modules/compute"
  project_id  = var.project_id
  region      = var.region
  zone        = var.zone
  environment = var.environment
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  
  # Network Configuration
  vpc_name    = module.networking.vpc_name
  subnet_name = module.networking.subnet_names[0]  # Use the first subnet
  
  # VM Configuration
  vm_instance_count      = var.vm_instance_count
  vm_machine_type        = var.vm_machine_type
  vm_image_family        = var.vm_image_family
  vm_image_project       = var.vm_image_project
  vm_disk_size          = var.vm_disk_size
  vm_disk_type          = var.vm_disk_type
  vm_tags               = var.vm_tags
  vm_enable_external_ip = var.vm_enable_external_ip
  ssh_public_key        = var.ssh_public_key
  
  # Managed Instance Group Configuration
  mig_target_size          = var.mig_target_size
  mig_enable_external_ip   = var.mig_enable_external_ip
  mig_max_surge           = var.mig_max_surge
  mig_max_unavailable     = var.mig_max_unavailable
  
  # Autoscaling Configuration
  mig_enable_autoscaling = var.mig_enable_autoscaling
  mig_min_replicas      = var.mig_min_replicas
  mig_max_replicas      = var.mig_max_replicas
  mig_cpu_target        = var.mig_cpu_target
  mig_cooldown_period   = var.mig_cooldown_period
  
  # Regional MIG Configuration
  create_regional_mig        = var.create_regional_mig
  regional_mig_target_size   = var.regional_mig_target_size
  
  depends_on = [module.networking]
}

module "security" {
  source                 = "./modules/security"
  project_id             = var.project_id
  secret_name            = "db-password"
  secret_value           = "SuperSecret123!"
  service_account_email  = "terraform-gcp-dev-compute-sa@${var.project_id}.iam.gserviceaccount.com"
}

module "cloudrun_app" {
  source       = "./modules/cloudruns"
  project_id   = var.project_id
  region       = "us-central1"
  service_name = "dev-user-service"
  image        = "docker.io/shahdsamir19/team-avail-test:latest"
  allow_unauthenticated = true

  env_vars = {
    ENV    = "dev"
    API_KEY = "123456"
  }

  resource_limits = {
    memory = "1Gi"
    cpu    = "2"
  }

  annotations = {
    "run.googleapis.com/ingress" = "internal"
  }

  labels = {
    team    = "devops"
    service = "user-api"
  }
}

