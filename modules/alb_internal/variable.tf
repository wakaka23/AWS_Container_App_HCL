variable "common" {
  type = object({
    env = string
  })
}

variable "network" {
  type = object({
    vpc_id    = string
    private_subnet_for_container_ids = list(string)
    security_group_for_internal_alb_id = string
  })
}