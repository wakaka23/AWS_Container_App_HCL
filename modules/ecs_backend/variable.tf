variable "common" {
  type = object({
    env        = string
    region     = string
    account_id = string
  })
}

variable "github_actions" {
  type = object({
    account_name = string
    repository   = string
  })
}

variable "network" {
  type = object({
    vpc_id                                  = string
    private_subnet_for_container_ids        = list(string)
    security_group_for_backend_container_id = string
  })
}

variable "alb_internal" {
  type = object({
    alb_listener_internal_prod_arn       = string
    alb_target_group_internal_blue_name  = string
    alb_target_group_internal_blue_arn   = string
    alb_listener_internal_test_arn       = string
    alb_target_group_internal_green_name = string
    alb_target_group_internal_green_arn  = string
  })
}

variable "secrets_manager" {
  type = object({
    secret_for_db_arn = string
  })
}

variable "repository" {
  type = string
}
