variable "network" {
  description = "Network information"
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
  })
}

variable "services" {
  description = "ECS services configuration"
  type = map(object({
    name           = string
    path           = string
    priority       = number
    desired_count  = number
    container_port = number
    cpu            = number
    memory         = number
    alb_state      = bool
    command        = list(string)
  }))
}

variable "image_url" {
  description = "image URL"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}