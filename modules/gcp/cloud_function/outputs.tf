# Outputs for GCP Cloud Function module

output "function_name" {
  description = "Name of the Cloud Function"
  value       = google_cloudfunctions_function.function.name
}

output "function_url" {
  description = "Trigger URL of the Cloud Function"
  value       = google_cloudfunctions_function.function.https_trigger_url
}

output "function_source_archive_url" {
  description = "Source archive URL"
  value       = google_storage_bucket_object.function_source.self_link
}

output "function_runtime" {
  description = "Runtime of the function"
  value       = google_cloudfunctions_function.function.runtime
}
