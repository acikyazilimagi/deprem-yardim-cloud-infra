output "iam_user_arn" {
  value = aws_iam_user.user.arn
}
output "iam_user_name" {
  value = aws_iam_user.user.name
}

output "user_id" {
  value = aws_iam_access_key.user.id
}

output "user_secret" {
  value     = aws_iam_access_key.user.secret
  sensitive = true
}