variable "network" {
  description = "Network information"
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
  })
}