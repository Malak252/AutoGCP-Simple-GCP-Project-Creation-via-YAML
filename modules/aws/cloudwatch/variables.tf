variable "workspace" {
  description = "Workspace name for resource naming"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "log_groups" {
  description = "CloudWatch log groups to create"
  type = list(object({
    name              = string
    retention_days    = optional(number, 14)
    kms_key_id       = optional(string)
    skip_destroy     = optional(bool, false)
  }))
  default = []
}

variable "dashboard_config" {
  description = "CloudWatch dashboard configuration"
  type = object({
    name = string
    widgets = list(object({
      type = string
      properties = object({
        metrics = optional(list(list(string)))
        title   = optional(string)
        region  = optional(string)
        stat    = optional(string, "Average")
        period  = optional(number, 300)
        view    = optional(string, "timeSeries")
        yAxis = optional(object({
          left = optional(object({
            min = optional(number)
            max = optional(number)
          }))
        }))
      })
    }))
  })
  default = null
}

variable "metric_alarms" {
  description = "CloudWatch metric alarms to create"
  type = list(object({
    name                = string
    metric_name         = string
    namespace          = string
    statistic          = string
    threshold          = number
    comparison_operator = string
    evaluation_periods = number
    period             = number
    dimensions         = optional(map(string), {})
    alarm_description  = optional(string)
    alarm_actions      = optional(list(string), [])
    ok_actions         = optional(list(string), [])
    treat_missing_data = optional(string, "missing")
    datapoints_to_alarm = optional(number)
    notification_topics = optional(list(object({
      name = string
      endpoints = list(object({
        protocol = string
        endpoint = string
      }))
    })), [])
  }))
  default = []
}

variable "log_metric_filters" {
  description = "CloudWatch log metric filters"
  type = list(object({
    name           = string
    log_group_name = string
    filter_pattern = string
    metric_transformation = object({
      name      = string
      namespace = string
      value     = optional(string, "1")
    })
  }))
  default = []
}

variable "log_streams" {
  description = "CloudWatch log streams to create"
  type = list(object({
    name           = string
    log_group_name = string
  }))
  default = []
}
