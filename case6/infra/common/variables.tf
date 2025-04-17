variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr_block         = string
    availability_zones = list(string)
  })
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "gateway_service_names" {
  description = "Gateway service names"
  type        = list(string)
}

variable "interface_service_names" {
  description = "Interface service names"
  type        = list(string)
}

variable "app_name" {
  description = "Application name"
  type        = string
}