terraform {
  backend "s3" {
    bucket               = "event-logger-terraform-state"
    region               = "ap-southeast-1"
    workspace_key_prefix = "env"
    key                  = "event-logger.tfstate"

    dynamodb_table = "event-logger-terraform-state-locks"
    encrypt        = true
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::297416720645:role/event-logger-provisioner-role"
  }
}