variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "full_environment" {
  type    = string
  default = "Development"
}

variable "region" {
  type    = string
  default = "us-east-2"
}
