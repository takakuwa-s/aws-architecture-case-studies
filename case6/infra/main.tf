terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.1"
    }
  }
}

locals {
  aws_region  = "ap-northeast-1"
  cidr_blocks = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      Environment = "dev"
      terraform   = "true"
      project     = "aws-architecture-case-study"
      case        = "case-study-6"
    }
  }
}

module "network" {
  count  = length(local.cidr_blocks)
  source = "./network/"
  vpc = {
    cidr_block = local.cidr_blocks[count.index]
    availability_zones = [
      "ap-northeast-1a",
      "ap-northeast-1c",
    ]
  }
  aws_region = local.aws_region
  gateway_service_names = [
    "com.amazonaws.${local.aws_region}.s3",
  ]
  interface_service_names = [
    "com.amazonaws.${local.aws_region}.ecr.api",
    "com.amazonaws.${local.aws_region}.ecr.dkr",
    "com.amazonaws.${local.aws_region}.logs",
    "com.amazonaws.${local.aws_region}.ssm",
    "com.amazonaws.${local.aws_region}.ssmmessages",
  ]
}

module "ecs_app" {
  source = "./ecs_app/"
  network = {
    vpc_id             = module.network[0].vpc_id
    private_subnet_ids = module.network[0].private_subnet_ids
  }
  services = {
    api = {
      name           = "api"
      path           = "/api/*"
      priority       = 10
      desired_count  = 1
      container_port = 80
      cpu            = 256
      memory         = 512
      alb_state      = true
      command        = ["uvicorn", "controller:app", "--host", "0.0.0.0", "--port", "80"]
    }
  }
  image_url  = aws_ecr_repository.ecr.repository_url
  aws_region = local.aws_region
  depends_on = [null_resource.docker_build_and_push]
}

module "ec2_app" {
  source = "./ec2_app/"
  network = {
    vpc_id             = module.network[1].vpc_id
    private_subnet_ids = module.network[1].private_subnet_ids
  }
  depends_on = [null_resource.docker_build_and_push]
}

module "eks_app" {
  source = "./eks_app/"
  network = {
    vpc_id             = module.network[2].vpc_id
    private_subnet_ids = module.network[2].private_subnet_ids
  }
  services = {
    api = {
      name           = "api"
      path           = "/api/*"
      priority       = 10
      desired_count  = 1
      container_port = 80
      cpu            = 256
      memory         = 512
      alb_state      = true
      command        = ["uvicorn", "controller:app", "--host", "0.0.0.0", "--port", "80"]
    }
  }
  image_url  = aws_ecr_repository.ecr.repository_url
  aws_region = local.aws_region
  depends_on = [null_resource.docker_build_and_push]
}