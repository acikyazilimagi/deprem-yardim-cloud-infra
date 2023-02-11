resource "aws_s3_bucket" "tf_state" {
  bucket_prefix = "tfstate-projects"
}

resource "aws_s3_bucket_acl" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf_state.id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_kms_key" "tf_state" {
  description         = "KMS Key for the general state buckets"
  enable_key_rotation = true
}

output "state_metadata" {
  value = {
    state_bucket = aws_s3_bucket.tf_state.id
    kms_key_arn  = aws_kms_key.tf_state.arn
  }
}