variable "region" {
  default = "eu-central-1"
}

# Name to be used on all the resources as identifier
variable "name" {
  default = "depremyardim-tf-openseacrh"
}

variable "vpc_id" {}

variable "public_subnets" {}

variable "private_subnets" {}

variable "iam_user_arn" {}
variable "iam_user_name" {}