variable "services" {
  type = list(object({
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
      name           = "app1"
      image          = "nginx:latest"
      path           = "/app1*"
      container_port = 80
      cpu            = 256
      memory         = 512
    },
    // app2
    {
      name           = "app2"
      image          = "httpd:latest"
      path           = "/app2*"
      container_port = 80
      cpu            = 256
      memory         = 512
    }
  ]
}
