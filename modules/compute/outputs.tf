# modules/compute/outputs.tf

# Service Account Outputs
output "compute_service_account_email" {
  description = "Email of the compute service account"
  value       = google_service_account.compute_sa.email
}

output "compute_service_account_id" {
  description = "ID of the compute service account"
  value       = google_service_account.compute_sa.id
}

# VM Instance Outputs
output "vm_instances" {
  description = "Information about created VM instances"
  value = {
    for instance in google_compute_instance.vm_instances : instance.name => {
      id                = instance.id
      self_link         = instance.self_link
      internal_ip       = instance.network_interface[0].network_ip
      external_ip       = length(instance.network_interface[0].access_config) > 0 ? instance.network_interface[0].access_config[0].nat_ip : null
      zone              = instance.zone
      machine_type      = instance.machine_type
      status            = instance.current_status
    }
  }
}

output "vm_instance_names" {
  description = "Names of the VM instances"
  value       = google_compute_instance.vm_instances[*].name
}

output "vm_instance_internal_ips" {
  description = "Internal IP addresses of VM instances"
  value       = google_compute_instance.vm_instances[*].network_interface.0.network_ip
}

output "vm_instance_external_ips" {
  description = "External IP addresses of VM instances"
  value = [
    for instance in google_compute_instance.vm_instances :
    length(instance.network_interface[0].access_config) > 0 ? 
    instance.network_interface[0].access_config[0].nat_ip : null
  ]
}

# Instance Template Outputs
output "instance_template_id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.template.id
}

output "instance_template_self_link" {
  description = "Self link of the instance template"
  value       = google_compute_instance_template.template.self_link
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.template.name
}

# Health Check Outputs
output "health_check_id" {
  description = "ID of the health check"
  value       = google_compute_health_check.mig_health_check.id
}

output "health_check_self_link" {
  description = "Self link of the health check"
  value       = google_compute_health_check.mig_health_check.self_link
}

# Managed Instance Group Outputs
output "mig_id" {
  description = "ID of the managed instance group"
  value       = google_compute_instance_group_manager.mig.id
}

output "mig_self_link" {
  description = "Self link of the managed instance group"
  value       = google_compute_instance_group_manager.mig.self_link
}

output "mig_instance_group" {
  description = "Instance group URL of the managed instance group"
  value       = google_compute_instance_group_manager.mig.instance_group
}

output "mig_name" {
  description = "Name of the managed instance group"
  value       = google_compute_instance_group_manager.mig.name
}

output "mig_target_size" {
  description = "Target size of the managed instance group"
  value       = google_compute_instance_group_manager.mig.target_size
}

# Autoscaler Outputs
output "autoscaler_id" {
  description = "ID of the autoscaler (if enabled)"
  value       = var.mig_enable_autoscaling ? google_compute_autoscaler.mig_autoscaler[0].id : null
}

output "autoscaler_self_link" {
  description = "Self link of the autoscaler (if enabled)"
  value       = var.mig_enable_autoscaling ? google_compute_autoscaler.mig_autoscaler[0].self_link : null
}

# Regional MIG Outputs (if created)
output "regional_mig_id" {
  description = "ID of the regional managed instance group (if created)"
  value       = var.create_regional_mig ? google_compute_region_instance_group_manager.regional_mig[0].id : null
}

output "regional_mig_self_link" {
  description = "Self link of the regional managed instance group (if created)"
  value       = var.create_regional_mig ? google_compute_region_instance_group_manager.regional_mig[0].self_link : null
}

output "regional_mig_instance_group" {
  description = "Instance group URL of the regional managed instance group (if created)"
  value       = var.create_regional_mig ? google_compute_region_instance_group_manager.regional_mig[0].instance_group : null
}

output "regional_autoscaler_id" {
  description = "ID of the regional autoscaler (if created and enabled)"
  value       = var.create_regional_mig && var.mig_enable_autoscaling ? google_compute_region_autoscaler.regional_autoscaler[0].id : null
}

# Summary Output
output "compute_resources_summary" {
  description = "Summary of all compute resources created"
  value = {
    vm_instances_count           = length(google_compute_instance.vm_instances)
    instance_template_name       = google_compute_instance_template.template.name
    mig_name                    = google_compute_instance_group_manager.mig.name
    mig_target_size             = google_compute_instance_group_manager.mig.target_size
    autoscaling_enabled         = var.mig_enable_autoscaling
    regional_mig_created        = var.create_regional_mig
    service_account_email       = google_service_account.compute_sa.email
  }
}