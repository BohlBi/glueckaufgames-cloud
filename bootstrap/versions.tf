terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Der Bootstrap legt den State-Bucket erst an. Sein eigener State bleibt
  # deshalb lokal (terraform.tfstate, per .gitignore ausgeschlossen).
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Component = "bootstrap"
    }
  }
}
