variable "vpc_id" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "dbuser" {
  type      = string
  sensitive = true
}
variable "dbpassword" {
  type      = string
  sensitive = true
}
