# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output declarations
# module.vpc.vpc_id 설명:
# moudle name: terraform-aws-modules/vpc
# => registry.terraform.io/browse/module?provider=aws
# => registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
# => Outputs => 검색: vpc_id
output "vpc_id" {
  description = "ID of project VPC"
  value       = module.vpc.vpc_id
}

# module.elb_http.elb_dns_name 설명:
# moudle name: terraform-aws-modules/elb
# => registry.terraform.io/browse/module?provider=aws 
# => registry.terraform.io/modules/terraform-aws-modules/elb/aws/latest
# => Outputs => 검색: elb_dns_name
output "lb_url" {
  description = "URL of load balancer"
  value       = "http://${module.elb_http.elb_dns_name}/"
}

# module.ec2_instance.instance_ids 설명:
# module name: terraform-aws-modules/ec2_instance
# => registry.terraform.io/browse/module?provider=aws 
# => registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest
# => Outputs => 검색: instance_ids => 검색되지 않음, 따라서 개별적으로 만들어짐
# => ~/modules/aws-instance/outputs.tf 파일 내용 확인
output "web_server_count" {
  description = "Number of web servers provisioned"
  value       = length(module.ec2_instances.instance_ids)
}

# aws_db_instance.database.username
# resource name: aws_db_instance
# => registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# => Argument Reference => 검색: username 
output "db_username" {
  description = "Database administrator username"
  value       = aws_db_instance.database.username
  sensitive   = true
}

# aws_db_instance.database.password
# resource name: aws_db_instance
# => registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# => Argument Reference => 검색: password
output "db_password" {
  description = "Database administrator password"
  value       = aws_db_instance.database.password
  sensitive   = true
}