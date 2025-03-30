variable "services" {
  type = list(object({
    idx            = number
    name           = string
    image          = string
    path           = string
    container_port = number
    cpu            = number
    memory         = number
  }))

  default = [
    // app1
    {
      idx            = 0
      name           = "app1"
      image          = "nginx:latest"
      path           = "/app1/*"
      container_port = 80
      cpu            = 256
      memory         = 512
    },
    // app2
    {
      idx            = 1
      name           = "app2"
      image          = "httpd:latest"
      path           = "/app2/*"
      container_port = 80
      cpu            = 256
      memory         = 512
    }
  ]
}

variable "ecr_image_version" {
  type    = string
  default = "1.0.0"
}

variable "default_user_password" {
  type    = string
  default = "P@ssw0rd!"
}