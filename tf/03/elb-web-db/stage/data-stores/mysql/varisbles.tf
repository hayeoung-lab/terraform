variable "dbuser" {
  type        = string
  description = "The user for the database"
  sensitive   = true
}

variable "dbpassword" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}
