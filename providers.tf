terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }

    linode = {
      source = "linode/linode"
      version = "2.2.0"
    }

  }
}
