provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "azs" {}
