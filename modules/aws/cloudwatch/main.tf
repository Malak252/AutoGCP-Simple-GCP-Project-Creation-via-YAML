# AWS CloudWatch Module - Main Configuration
# Creates log groups, dashboards, metric alarms, and SNS notifications
# File: modules/aws/cloudwatch/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "this" {
  for_each = {
    for lg in var.log_groups : lg.name => lg
  }

  name              = each.value.name
  retention_in_days = each.value.retention_days
  kms_key_id       = each.value.kms_key_id
  skip_destroy     = each.value.skip_destroy

  tags = merge(var.tags, {
    Name      = "${each.value.name}-${var.workspace}"
    Workspace = var.workspace
    Project   = var.project_name
  })
}

# CloudWatch Log Streams
resource "aws_cloudwatch_log_stream" "this" {
  for_each = {
    for ls in var.log_streams : "${ls.log_group_name}-${ls.name}" => ls
  }

  name           = each.value.name
  log_group_name = each.value.log_group_name

  depends_on = [aws_cloudwatch_log_group.this]
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = {
    for lmf in var.log_metric_filters : lmf.name => lmf
  }

  name           = each.value.name
  log_group_name = each.value.log_group_name
  pattern        = each.value.filter_pattern  # Changed from filter_pattern to pattern

  metric_transformation {
    name      = each.value.metric_transformation.name
    namespace = each.value.metric_transformation.namespace
    value     = each.value.metric_transformation.value
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

# Extract all unique SNS topics from all alarms
locals {
  all_sns_topics = flatten([
    for alarm in var.metric_alarms : [
      for topic in(alarm.notification_topics != null ? alarm.notification_topics : []) : {
        key       = "${alarm.name}-${topic.name}"
        name      = topic.name
        alarm     = alarm.name
        endpoints = topic.endpoints
      }
    ]
  ])

  sns_topics_map = {
    for topic in local.all_sns_topics : topic.name => topic...
  }

  # Create unique SNS topics
  unique_sns_topics = {
    for name, topics in local.sns_topics_map : name => topics[0]
  }

  # Create subscription map
  sns_subscriptions = flatten([
    for topic_name, topic in local.unique_sns_topics : [
      for idx, endpoint in topic.endpoints : {
        key      = "${topic_name}-${idx}"
        topic    = topic_name
        protocol = endpoint.protocol
        endpoint = endpoint.endpoint
      }
    ]
  ])
}

# Create SNS Topics
resource "aws_sns_topic" "alarm_notifications" {
  for_each = local.unique_sns_topics

  name = "${each.key}-${var.workspace}-${var.project_name}"

  tags = merge(var.tags, {
    Name      = "${each.key}-${var.workspace}"
    Workspace = var.workspace
    Project   = var.project_name
    Purpose   = "CloudWatch Alarms"
  })
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "notifications" {
  for_each = {
    for sub in local.sns_subscriptions : sub.key => sub
  }

  topic_arn = aws_sns_topic.alarm_notifications[each.value.topic].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = {
    for alarm in var.metric_alarms : alarm.name => alarm
  }

  alarm_name          = "${each.value.name}-${var.workspace}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  treat_missing_data  = each.value.treat_missing_data
  datapoints_to_alarm = each.value.datapoints_to_alarm

  # Dimensions
  dimensions = each.value.dimensions

  # Alarm Actions - SNS Topics
  alarm_actions = concat(
    each.value.alarm_actions,
    each.value.notification_topics != null ? [
      for topic in each.value.notification_topics :
      aws_sns_topic.alarm_notifications[topic.name].arn
    ] : []
  )

  # OK Actions
  ok_actions = concat(
    each.value.ok_actions,
    each.value.notification_topics != null ? [
      for topic in each.value.notification_topics :
      aws_sns_topic.alarm_notifications[topic.name].arn
    ] : []
  )

  tags = merge(var.tags, {
    Name      = "${each.value.name}-${var.workspace}"
    Workspace = var.workspace
    Project   = var.project_name
  })

  depends_on = [aws_sns_topic.alarm_notifications]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "this" {
  count = var.dashboard_config != null ? 1 : 0

  dashboard_name = "${var.dashboard_config.name}-${var.workspace}"

  dashboard_body = jsonencode({
    widgets = [
      for widget in var.dashboard_config.widgets : {
        type   = widget.type
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = merge(widget.properties, {
          region = widget.properties.region != null ? widget.properties.region : data.aws_region.current.name
          title  = widget.properties.title != null ? widget.properties.title : "Metrics"
        })
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs (if needed for cross-service access)
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

# Output locals for reference
locals {
  log_group_names = [for lg in aws_cloudwatch_log_group.this : lg.name]
  log_group_arns  = [for lg in aws_cloudwatch_log_group.this : lg.arn]
  sns_topic_arns  = [for topic in aws_sns_topic.alarm_notifications : topic.arn]
}
