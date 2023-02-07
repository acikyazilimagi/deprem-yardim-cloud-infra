resource "random_string" "suffix" {
  length  = 4
  special = false
}

resource "aws_iam_user" "user" {
  name = "${var.username}" # "${var.username}-${random_string.suffix.result}"
}

resource "aws_iam_access_key" "user" {
  user       = aws_iam_user.user.name
  depends_on = [aws_iam_user.user]
}
