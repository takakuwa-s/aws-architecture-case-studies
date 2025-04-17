variable "network" {
  description = "Network information"
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
  })
}
variable "image_url" {
  description = "image URL"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cloud_Watch_log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "sg_ids" {
  description = "Security group IDs"
  type = object({
    alb_sg_id = string
    app_sg_id = string
  })
}