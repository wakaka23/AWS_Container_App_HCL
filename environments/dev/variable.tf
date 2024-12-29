variable "db" {
  type = object({
    name                    = string
    db_master_user_name     = string
    db_master_user_password = string
    db_user_name            = string
    db_user_password        = string
  })
}

variable "github_actions" {
  type = object({
    account_name = string
    repository   = string
  }) 
}
