# versions.tf
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}
