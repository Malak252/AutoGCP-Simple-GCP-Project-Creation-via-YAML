project_id = "durable-destiny-465315-u0"
project_name = "terraform-gcp"
region       = "us-central1"
zone         = "us-central1-a"
environment  = "dev"
created_by   = "your-name"

# Network Configuration
subnet_cidr_main     = "10.0.1.0/24"
subnet_cidr_pods     = "10.1.0.0/16"
subnet_cidr_services = "10.2.0.0/16"

# VM Configuration
vm_machine_type   = "e2-medium"
vm_image_family   = "ubuntu-2004-lts"
vm_image_project  = "ubuntu-os-cloud"
vm_disk_size      = 20
vm_disk_type      = "pd-standard"

# Database Configuration
database_version     = "MYSQL_8_0"
database_tier        = "db-f1-micro"
database_disk_size   = 10
database_disk_type   = "PD_SSD"
database_backup_enabled = true
database_name        = "appdb"
database_user_name   = "appuser"

# GKE Configuration
gke_kubernetes_version = "1.27"
gke_machine_type      = "e2-medium"
gke_node_count        = 3
gke_min_node_count    = 1
gke_max_node_count    = 10
gke_disk_size         = 20
gke_disk_type         = "pd-standard"
gke_image_type        = "COS_CONTAINERD"
gke_preemptible       = true