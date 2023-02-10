terraform {
  aws = {
    source                = "hashicorp/aws"
    configuration_aliases = [aws.source, aws.target]
  }
}