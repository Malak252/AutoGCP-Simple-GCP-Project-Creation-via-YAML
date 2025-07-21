# Outputs for GCP Monitoring module

output "notification_channel_name" {
  description = "Name of the notification channel"
  value       = google_monitoring_notification_channel.email.name
}

output "high_cpu_alert_policy_name" {
  description = "Name of the high CPU alert policy"
  value       = google_monitoring_alert_policy.high_cpu.name
}

output "high_memory_alert_policy_name" {
  description = "Name of the high memory alert policy"
  value       = google_monitoring_alert_policy.high_memory.name
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main.id}"
}
