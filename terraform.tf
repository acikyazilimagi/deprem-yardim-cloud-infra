terraform {
  cloud {
    organization = "afetyardim"

    workspaces {
      name = "deprem-yardim-cloud-infra"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
  }
}
