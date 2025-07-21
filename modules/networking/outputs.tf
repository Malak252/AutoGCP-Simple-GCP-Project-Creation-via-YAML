output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC self link"
  value       = google_compute_network.vpc.self_link
}

output "vpc_gateway_ipv4" {
  description = "VPC gateway IPv4"
  value       = google_compute_network.vpc.gateway_ipv4
}


output "subnet_ids" {
  description = "Subnet IDs"
  value       = google_compute_subnetwork.subnets[*].id
}

output "subnet_names" {
  description = "Subnet names"
  value       = google_compute_subnetwork.subnets[*].name
}

output "subnet_self_links" {
  description = "Subnet self links"
  value       = google_compute_subnetwork.subnets[*].self_link
}

output "subnet_ip_ranges" {
  description = "Subnet IP ranges"
  value       = google_compute_subnetwork.subnets[*].ip_cidr_range
}

output "subnet_regions" {
  description = "Subnet regions"
  value       = google_compute_subnetwork.subnets[*].region
}

output "subnet_gateway_addresses" {
  description = "Subnet gateway addresses"
  value       = google_compute_subnetwork.subnets[*].gateway_address
}


output "nat_router_ids" {
  description = "Cloud Router IDs"
  value       = google_compute_router.router[*].id
}

output "nat_ids" {
  description = "Cloud NAT IDs"
  value       = google_compute_router_nat.nat[*].id
}

output "nat_ip_addresses" {
  description = "NAT IP addresses"
  value       = google_compute_address.nat_ips[*].address
}


