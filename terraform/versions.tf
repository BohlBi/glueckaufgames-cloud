terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Der Bucket kommt beim init dazu (Ausgabe "state_bucket" aus bootstrap/):
  # terraform init -backend-config="bucket=<state_bucket>"
  backend "s3" {
    key          = "website/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  default_tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# Primäre Region: Frankfurt
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = local.default_tags
  }
}

# Replikat-Region: Irland
provider "aws" {
  alias  = "replica"
  region = var.replica_region

  default_tags {
    tags = local.default_tags
  }
}

# CloudFront-Metriken liegen in CloudWatch immer in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}
