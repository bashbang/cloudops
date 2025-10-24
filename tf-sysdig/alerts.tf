# Define Sysdig alerts with detailed attributes for all environments and metrics
resource "sysdig_monitor_alert_v2_metric" "pod_metrics" {
  for_each = local.all_metrics

  name              = each.value.name
  description       = each.value.description
  enabled           = each.value.enabled
  severity          = each.value.severity
  metric            = each.value.metric
  group_aggregation = each.value.group_aggregation
  time_aggregation  = each.value.time_aggregation
  operator          = each.value.operator
  threshold         = each.value.threshold

  dynamic "scope" {
    for_each = [
      {
        label    = "kube_namespace_name"
        operator = "equals"
        values   = [each.value.namespace_name]
      }
    ]
    content {
      label    = scope.value.label
      operator = scope.value.operator
      values   = scope.value.values
    }
  }

  notification_channels {
    id                     = sysdig_monitor_notification_channel_email.tf_sre.id
    renotify_every_minutes = 60
  }

  custom_notification {
    subject = each.value.notification_subject
    prepend = "Alert Details:"
    append  = "Please check the system immediately."
  }

  range_seconds = each.value.range_seconds
}
