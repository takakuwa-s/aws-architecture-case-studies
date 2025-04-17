terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.1"
    }
  }
}

locals {
  aws_region = "ap-northeast-1"
  app_commons = {
    "ec2" : {
      cidr_block            = "10.0.0.0/16"
      availability_zones    = ["ap-northeast-1a", "ap-northeast-1c", ]
      gateway_service_names = []
      interface_service_names = [
        "com.amazonaws.${local.aws_region}.logs",
        "com.amazonaws.${local.aws_region}.ssm",
        "com.amazonaws.${local.aws_region}.ssmmessages",
      ]
    },
    "ecs" : {
      cidr_block            = "10.1.0.0/16"
      availability_zones    = ["ap-northeast-1a", "ap-northeast-1c", ]
      gateway_service_names = ["com.amazonaws.${local.aws_region}.s3", ]
      interface_service_names = [
        "com.amazonaws.${local.aws_region}.ecr.api",
        "com.amazonaws.${local.aws_region}.ecr.dkr",
        "com.amazonaws.${local.aws_region}.logs",
        "com.amazonaws.${local.aws_region}.ssm",
        "com.amazonaws.${local.aws_region}.ssmmessages",
      ]
    },
    "eks" : {
      cidr_block            = "10.2.0.0/16"
      availability_zones    = ["ap-northeast-1a", "ap-northeast-1c", ]
      gateway_service_names = ["com.amazonaws.${local.aws_region}.s3", ]
      interface_service_names = [
        "com.amazonaws.${local.aws_region}.ecr.api",
        "com.amazonaws.${local.aws_region}.ecr.dkr",
        "com.amazonaws.${local.aws_region}.logs",
        "com.amazonaws.${local.aws_region}.ssm",
        "com.amazonaws.${local.aws_region}.ssmmessages",
      ]
    }
  }
  ecr_image_url = "${aws_ecr_repository.ecr.repository_url}:latest"
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

module "common" {
  for_each = local.app_commons
  source   = "./common/"
  app_name = each.key
  vpc = {
    cidr_block         = each.value.cidr_block
    availability_zones = each.value.availability_zones
  }
  aws_region              = local.aws_region
  gateway_service_names   = each.value.gateway_service_names
  interface_service_names = each.value.interface_service_names
}

module "ecs_app" {
  source = "./ecs_app/"
  network = {
    vpc_id             = module.common["ecs"].vpc_id
    private_subnet_ids = module.common["ecs"].private_subnet_ids
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
      environment = [
        {
          name  = "ENV_CONTEXT"
          value = "ecs"
        },
        {
          name  = "EC2_ENDPOINT"
          value = "http://${module.ec2_app.alb_dns_name}"
        },
        {
          name  = "ECS_ENDPOINT"
          value = ""
        },
        {
          name  = "EKS_ENDPOINT"
          value = ""
        },

      ]
    }
  }
  image_url                  = local.ecr_image_url
  aws_region                 = local.aws_region
  cloud_Watch_log_group_name = module.common["ecs"].cloud_Watch_log_group_name
  sg_ids                     = module.common["ecs"].sg_ids
  depends_on                 = [null_resource.docker_build_and_push]
}

module "ec2_app" {
  source = "./ec2_app/"
  network = {
    vpc_id             = module.common["ec2"].vpc_id
    private_subnet_ids = module.common["ec2"].private_subnet_ids
  }
  aws_region                 = local.aws_region
  cloud_Watch_log_group_name = module.common["ec2"].cloud_Watch_log_group_name
  sg_ids                     = module.common["ec2"].sg_ids
  depends_on                 = [null_resource.docker_build_and_push]
}

module "eks_app" {
  source = "./eks_app/"
  network = {
    vpc_id             = module.common["eks"].vpc_id
    private_subnet_ids = module.common["eks"].private_subnet_ids
  }
  image_url                  = aws_ecr_repository.ecr.repository_url
  aws_region                 = local.aws_region
  cloud_Watch_log_group_name = module.common["ec2"].cloud_Watch_log_group_name
  sg_ids                     = module.common["ec2"].sg_ids
  depends_on                 = [null_resource.docker_build_and_push]
}