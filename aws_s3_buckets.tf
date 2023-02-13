resource "aws_s3_bucket" "buckets" {
  for_each = toset( ["aws-waf-logs-afetorg", "afet-logs-alb", "afet-logs-cloudtrail", "afet-logs-vpcflowlogs"] )
  bucket = each.key
  acl    = "private"
}