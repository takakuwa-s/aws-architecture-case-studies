terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.1"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Environment = "dev"
      terraform   = "true"
      project     = "aws-architecture-case-study"
      case        = "case-study-2"
    }
  }
}