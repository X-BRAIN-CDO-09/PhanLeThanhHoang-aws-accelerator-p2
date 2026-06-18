# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state (S3 + DynamoDB). Bootstrap via terraform/backend-setup.
  # Uncomment after running `terraform apply` in backend-setup.
  # backend "s3" {
  #   bucket         = "flipkart-tfstate-CHANGEME"
  #   key            = "w10/flipkart/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "flipkart-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "flipkart"
      ManagedBy = "terraform"
      Week      = "w10"
    }
  }
}
