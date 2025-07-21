# modules/compute/main.tf

# Data sources
data "google_compute_image" "vm_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

# Service Account for compute instances
resource "google_service_account" "compute_sa" {
  account_id   = "${var.name_prefix}-compute-sa"
  display_name = "Service Account for Compute Instances"
  description  = "Service account used by compute instances"
}

# IAM binding for service account
resource "google_project_iam_member" "compute_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.editor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

# Startup script for instances
locals {
  startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create a simple index page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Welcome to ${var.environment}</title>
    </head>
    <body>
        <h1>Hello from ${var.environment} environment!</h1>
        <p>Instance: $(hostname)</p>
        <p>Zone: $(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)</p>
    </body>
    </html>
HTML
    
    systemctl restart nginx
  EOF
}

# Individual VM Instances
resource "google_compute_instance" "vm_instances" {
  count = var.vm_instance_count
  
  name         = "${var.name_prefix}-vm-${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = var.zone
  
  tags = concat(var.vm_tags, ["vm-instance"])
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.vm_image.self_link
      size  = var.vm_disk_size
      type  = var.vm_disk_type
    }
  }
  
  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnet_name
    
    dynamic "access_config" {
      for_each = var.vm_enable_external_ip ? [1] : []
      content {
        // Ephemeral external IP
      }
    }
  }
  
  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["cloud-platform"]
  }
  
  metadata_startup_script = local.startup_script
  
  metadata = merge(var.common_tags, {
    ssh-keys = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : ""
  })
  
  labels = var.common_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# Instance Template
resource "google_compute_instance_template" "template" {
  name_prefix = "${var.name_prefix}-template-"
  description = "Instance template for ${var.environment} environment"
  
  tags = concat(var.vm_tags, ["template-instance"])
  
  machine_type = var.vm_machine_type
  
  disk {
    source_image = data.google_compute_image.vm_image.self_link
    disk_size_gb = var.vm_disk_size
    disk_type    = var.vm_disk_type
    auto_delete  = true
    boot         = true
  }
  
  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnet_name
    
    dynamic "access_config" {
      for_each = var.mig_enable_external_ip ? [1] : []
      content {
        // Ephemeral external IP
      }
    }
  }
  
  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["cloud-platform"]
  }
  
  metadata_startup_script = local.startup_script
  
  metadata = merge(var.common_tags, {
    ssh-keys = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : ""
  })
  
  labels = var.common_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# Health Check for Managed Instance Group
resource "google_compute_health_check" "mig_health_check" {
  name               = "${var.name_prefix}-mig-health-check"
  check_interval_sec = 30
  timeout_sec        = 10
  
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Managed Instance Group
resource "google_compute_instance_group_manager" "mig" {
  name               = "${var.name_prefix}-mig"
  base_instance_name = "${var.name_prefix}-mig-instance"
  zone               = var.zone
  target_size        = var.mig_target_size
  
  version {
    instance_template = google_compute_instance_template.template.id
  }
  
  auto_healing_policies {
    health_check      = google_compute_health_check.mig_health_check.id
    initial_delay_sec = 60
  }
  
  update_policy {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_fixed         = var.mig_max_surge
    max_unavailable_fixed   = var.mig_max_unavailable
  }
  
  named_port {
    name = "http"
    port = 80
  }
  
  named_port {
    name = "https"
    port = 443
  }
}

# Autoscaler for Managed Instance Group
resource "google_compute_autoscaler" "mig_autoscaler" {
  count = var.mig_enable_autoscaling ? 1 : 0
  
  name   = "${var.name_prefix}-mig-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.mig.id
  
  autoscaling_policy {
    max_replicas    = var.mig_max_replicas
    min_replicas    = var.mig_min_replicas
    cooldown_period = var.mig_cooldown_period
    
    cpu_utilization {
      target = var.mig_cpu_target
    }
  }
}

# Regional Managed Instance Group (optional)
resource "google_compute_region_instance_group_manager" "regional_mig" {
  count = var.create_regional_mig ? 1 : 0
  
  name               = "${var.name_prefix}-regional-mig"
  base_instance_name = "${var.name_prefix}-regional-mig-instance"
  region             = var.region
  target_size        = var.regional_mig_target_size
  
  version {
    instance_template = google_compute_instance_template.template.id
  }
  
  auto_healing_policies {
    health_check      = google_compute_health_check.mig_health_check.id
    initial_delay_sec = 60
  }
  
  update_policy {
    type                    = "PROACTIVE"
    minimal_action          = "REPLACE"
    max_surge_fixed         = var.mig_max_surge
    max_unavailable_fixed   = var.mig_max_unavailable
  }
  
  named_port {
    name = "http"
    port = 80
  }
  
  named_port {
    name = "https"
    port = 443
  }
}

# Regional Autoscaler (optional)
resource "google_compute_region_autoscaler" "regional_autoscaler" {
  count = var.create_regional_mig && var.mig_enable_autoscaling ? 1 : 0
  
  name   = "${var.name_prefix}-regional-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.regional_mig[0].id
  
  autoscaling_policy {
    max_replicas    = var.mig_max_replicas
    min_replicas    = var.mig_min_replicas
    cooldown_period = var.mig_cooldown_period
    
    cpu_utilization {
      target = var.mig_cpu_target
    }
  }
}