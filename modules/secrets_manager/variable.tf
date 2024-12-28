variable "common" {
  type = object({
    env = string
  })
}

variable "rds" {
  type = object({
    db_instance_address = string
  })
}

variable "db_info" {
  type = object({
    name                    = string
    db_user_name            = string
    db_user_password        = string
  })
}