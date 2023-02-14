resource "aws_s3_bucket" "buckets" {
  for_each = toset(["aws-waf-logs-afetorg", "afet-logs-alb", "afet-logs-cloudtrail", "afet-logs-vpcflowlogs"])
  bucket   = each.key

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}