# Define a notification channel
resource "sysdig_monitor_notification_channel_email" "tf_sre" {
    name                    = "TF SRE"
    enabled                 = true
    recipients              = ["chris@bashbang.com"]
    notify_when_ok          = true
    notify_when_resolved    = true
    send_test_notification  = true
    share_with_current_team = true  # IMPORTANT - Needed to share with the current team only. Default would be all teams which results in a 403 error
}
