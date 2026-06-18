# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
variable "project" {
  type = string
}

variable "db_secret_name" {
  type = string
}

variable "db_initial_password" {
  type      = string
  sensitive = true
}
