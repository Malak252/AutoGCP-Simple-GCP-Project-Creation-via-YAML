output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.project.number
}
output "cloud_run_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = module.cloudrun_app.url
}
