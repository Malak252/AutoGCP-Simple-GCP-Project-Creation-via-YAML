# GCP Cloud Storage Module

# Enable required APIs
resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Cloud Storage Bucket
resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  location      = var.location
  project       = var.project_id
  storage_class = var.storage_class
  force_destroy = true

  # Versioning
  versioning {
    enabled = true
  }

  # Lifecycle rules
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # CORS configuration
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Labels
  labels = var.labels

  depends_on = [google_project_service.storage_api]
}

# Bucket IAM binding for public read access (optional)
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Example object in the bucket
resource "google_storage_bucket_object" "readme" {
  name    = "README.txt"
  bucket  = google_storage_bucket.bucket.name
  content = "This bucket was created by Terraform multi-cloud deployment."
}
