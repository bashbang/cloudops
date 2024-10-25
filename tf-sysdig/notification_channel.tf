# # Define a notification channel
# resource "sysdig_monitor_notification_channel_email" "tf_sre" {
#     name                    = "TF SRE"
#     recipients              = ["chris@bashbang.com"]
#     enabled                 = true
#     notify_when_ok          = true
#     notify_when_resolved    = true
#     send_test_notification  = true
# }
