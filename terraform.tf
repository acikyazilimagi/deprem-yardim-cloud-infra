terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "deprem-yardim-cloud-infra"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
  }
}
