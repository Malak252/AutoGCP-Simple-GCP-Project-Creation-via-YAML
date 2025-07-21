# GCP Cloud Function Module

# Enable required APIs
resource "google_project_service" "cloudfunctions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloudbuild_api" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Storage bucket for function source code
resource "google_storage_bucket" "function_bucket" {
  name          = "${var.project_id}-${var.function_name}-source"
  location      = var.region
  force_destroy = true
  
  labels = var.labels
}

# Upload function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "${var.function_name}-${timestamp()}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = var.source_archive
}

# Cloud Function
resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.runtime
  entry_point = var.entry_point

  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
}
# IAM binding to make function publicly accessible
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
