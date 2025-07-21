resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
    metadata {
      labels = var.labels

      annotations = {

        "run.googleapis.com/ingress" = var.ingress_type
    }
    }
  

  template {
    

    spec {
      containers {
        image = var.image

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        ports {
          container_port = var.container_port
        }

        resources {
          limits = var.resource_limits
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
