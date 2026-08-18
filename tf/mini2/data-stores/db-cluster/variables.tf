variable "dbuser" {
  description = "DB 사용자 이름"
  type        = string
  sensitive   = true
}

variable "dbpassword" {
  description = "DB 비밀번호"
  type        = string
  sensitive   = true
}
