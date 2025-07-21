# GCP Monitoring Module

# Enable required APIs
resource "google_project_service" "monitoring_api" {
  project = var.project_id
  service = "monitoring.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Notification Channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  project      = var.project_id
  
  labels = {
    email_address = var.notification_channel
  }

  depends_on = [google_project_service.monitoring_api]
}

# Alert Policy for High CPU Usage
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "High CPU Usage Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.name]
  
  alert_strategy {
    auto_close = "604800s" # 7 days
  }
  
  depends_on = [google_project_service.monitoring_api]
}

# Alert Policy for High Memory Usage
resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "High Memory Usage Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Memory usage above 85%"
    
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.name]
  
  alert_strategy {
    auto_close = "604800s"
  }
  
  depends_on = [google_project_service.monitoring_api]
}

# Custom Dashboard
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "Multi-Cloud Infrastructure Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "CPU Utilization"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Utilization"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
  
  depends_on = [google_project_service.monitoring_api]
}
