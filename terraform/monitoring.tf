variable "alert_email" {
  type = string
}

locals {
  region       = "eu-north-1"
  cluster_name = aws_ecs_cluster.main.name
  service_name = aws_ecs_service.app.name
  alb_suffix   = aws_lb.main.arn_suffix
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "inventory-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Екземпляри: бажана і фактична кількість"
          region = local.region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["ECS/ContainerInsights", "DesiredTaskCount", "ClusterName", local.cluster_name, "ServiceName", local.service_name],
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", local.cluster_name, "ServiceName", local.service_name]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Завантаження CPU, %"
          region = local.region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.cluster_name, "ServiceName", local.service_name]
          ]
          annotations = {
            horizontal = [{ label = "Ціль масштабування 60%", value = 60 }]
          }
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Запити за хвилину"
          region = local.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffix]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Латентність p95, с"
          region = local.region
          stat   = "p95"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffix]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "Відповіді 5xx"
          region = local.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffix]
          ]
        }
      }
    ]
  })
}

resource "aws_sns_topic" "alerts" {
  name = "inventory-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "inventory-cpu-high"
  alarm_description   = "CPU > 70% протягом 2 хвилин"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 70
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}