# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode           = var.routing_mode
  description            = "VPC network for ${var.environment} environment"
  
  depends_on = [google_project_service.compute]
}

# Enable required APIs
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  count = length(var.subnets)
  
  name          = var.subnets[count.index].name
  ip_cidr_range = var.subnets[count.index].ip_cidr_range
  region        = var.subnets[count.index].region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = var.subnets[count.index].private_ip_google_access
  
  dynamic "secondary_ip_range" {
    for_each = var.subnets[count.index].secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  
  dynamic "log_config" {
    for_each = var.subnets[count.index].flow_logs_enabled ? [1] : []
    content {
      aggregation_interval = var.subnets[count.index].flow_logs_config.aggregation_interval
      flow_sampling       = var.subnets[count.index].flow_logs_config.flow_sampling
      metadata           = var.subnets[count.index].flow_logs_config.metadata
    }
  }
  
  depends_on = [google_compute_network.vpc]
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  count = var.enable_nat ? 1 : 0
  
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  
  depends_on = [google_compute_network.vpc]
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  count = var.enable_nat ? 1 : 0
  
  name   = "${var.name_prefix}-nat"
  router = google_compute_router.router[0].name
  region = var.region
  
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat
  
  dynamic "subnetwork" {
    for_each = var.nat_subnetworks
    content {
      name                    = subnetwork.value.name
      source_ip_ranges_to_nat = subnetwork.value.source_ip_ranges_to_nat
    }
  }
  
  log_config {
    enable = var.nat_log_config.enable
    filter = var.nat_log_config.filter
  }
  
  depends_on = [google_compute_router.router]
}

# Static IP addresses for NAT (optional)
resource "google_compute_address" "nat_ips" {
  count = var.enable_nat && var.nat_ip_allocate_option == "MANUAL_ONLY" ? var.nat_ip_count : 0
  
  name   = "${var.name_prefix}-nat-ip-${count.index + 1}"
  region = var.region
  
  depends_on = [google_project_service.compute]
}

