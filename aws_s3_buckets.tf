resource "aws_s3_bucket" "buckets" {
  for_each = toset( ["aws-waf-logs-afetorg", "afet-logs-alb", "afet-logs-cloudtrail", "afet-logs-vpcflowlogs"] )
  bucket = each.key
  object_lock_configuration {
    object_lock_enabled = "Enabled"
    rule {
      default_retention {
        mode = "COMPLIANCE"
        days = 45
      }
    }
  }
}
