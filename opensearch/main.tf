### Amazon OpenSearch ###

resource "aws_security_group" "OpenSearch" {
  name        = var.name
  description = "${var.name} - Managed by Terraform"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_iam_service_linked_role" "OpenSearch" {
#   aws_service_name = "opensearchservice.amazonaws.com"
# }

data "aws_caller_identity" "current" {}

resource "aws_opensearch_domain" "OpenSearch" {
  domain_name    = var.name
  engine_version = "OpenSearch_1.3"

  cluster_config {
    instance_type          = "t3.small.search"
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  vpc_options {
    subnet_ids = [var.public_subnets[0]]

    security_group_ids = [aws_security_group.OpenSearch.id]
  }

  # advanced_options = {
  #   "rest.action.multi.allow_explicit_index" = "true"
  # }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": {
               "AWS": "*"
              },
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${var.name}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain = "${var.name}"
  }

  #  depends_on = [aws_iam_service_linked_role.OpenSearch]
}


### IAM Role ###
resource "aws_iam_role" "role-efk" {
  name = var.name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.iam_user_name}"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role-efk" {
  role       = aws_iam_role.role-efk.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess"
}

