locals {
  # Define common scope as a local variable
  common_scope = [
    {
      label    = "kube_cluster_name"
      operator = "equals"
      values   = ["gold"]
    },
    {
      label    = "kube_namespace_name"
      operator = "equals"
      values   = ["d22e7c-dev"]
    },
    {
      label    = "kube_deployment_name"
      operator = "equals"
      values   = ["eibc-wordpress"]
    }
  ]

  # Define environments
  environments = {
    dev  = "d22e7c-dev"
    test = "d22e7c-test"
    prod = "d22e7c-prod"
  }

  # Define pod metrics
  pod_metrics = {
    "Pod CPU Usage" = {
      metric               = "sysdig_program_cpu_cores_used_percent"
      description          = "Alert when 'sysdig_program_cpu_cores_used_percent' exceeds threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = ">"
      threshold            = 80
      notification_subject = "Pod CPU Usage Alert Status"
      range_seconds        = 60
    }

    "Pod Memory Usage" = {
      metric               = "sysdig_program_memory_used_percent"
      description          = "Alert when 'sysdig_program_memory_used_percent' exceeds threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = ">"
      threshold            = 80
      notification_subject = "Pod Memory Usage Alert Status"
      range_seconds        = 60
    }

    "Pod Restarts" = {
      metric               = "kube_pod_sysdig_restart_count"
      description          = "Alert when 'kube_pod_sysdig_restart_count' exceeds threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "max"
      time_aggregation     = "avg"
      operator             = ">"
      threshold            = 5
      notification_subject = "Pod Restart Alert Status"
      range_seconds        = 300
    }

    "HTTP Error Count" = {
      metric               = "sysdig_container_net_http_error_count"
      description          = "Alert when 'sysdig_container_net_http_error_count' exceeds the threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = ">"
      threshold            = 25
      notification_subject = "Pod HTTP Error Count Alert"
      range_seconds        = 300
    }

    "Replica Count Below Minimum" = {
      metric               = "kube_deployment_status_replicas"
      description          = "Alert when 'kube_deployment_status_replicas' falls below the threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = "<"
      threshold            = 3
      notification_subject = "Replica Count Alert"
      range_seconds        = 60
    }

    "Pod Ready Status" = {
      metric               = "kube_pod_sysdig_status_ready"
      description          = "Alert when 'kube_pod_sysdig_status_ready' falls below the threshold"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = "<"
      threshold            = 1
      notification_subject = "Pod Ready Status Alert"
      range_seconds        = 60
    }

    "Pod Unready Status" = {
      metric               = "kube_pod_sysdig_status_ready"
      description          = "Alert when 'kube_pod_sysdig_status_ready' is unready for more than 5 minutes"
      enabled              = true
      severity             = "high"
      group_aggregation    = "avg"
      time_aggregation     = "avg"
      operator             = "<"
      threshold            = 1
      notification_subject = "Pod Unready Status Alert"
      range_seconds        = 300
    }
  }

  all_metrics = merge([
    for env, ns in local.environments : {
      for metric_name, metric_info in local.pod_metrics : "${env}-${metric_name}" => {
        name                 = "${env} - ${metric_name}"
        namespace_name       = ns
        metric               = metric_info.metric
        description          = metric_info.description
        enabled              = metric_info.enabled
        severity             = metric_info.severity
        group_aggregation    = metric_info.group_aggregation
        time_aggregation     = metric_info.time_aggregation
        operator             = metric_info.operator
        threshold            = metric_info.threshold
        notification_subject = metric_info.notification_subject
        range_seconds        = metric_info.range_seconds
      }
    }
  ]...)

}
