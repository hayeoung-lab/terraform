output "vpc_id" {
  value = module.net.vpc_id
}

output "primary_address" {
  value = module.db.primary_address
}

output "primary_port" {
  value = module.db.primary_port
}
