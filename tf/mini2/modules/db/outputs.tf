output "primary_address" {
  value = aws_db_instance.primary.address
}
output "primary_port" {
  value = aws_db_instance.primary.port
}
output "replica_address" {
  value = aws_db_instance.replica.address
}
