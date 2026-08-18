terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "hayoung-tfstate-0104"
    key            = "data-stores/db-cluster/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "net" {
  source = "../../modules/net"

  vpc_name = "db-vpc"
}

module "db" {
  source = "../../modules/db"

  vpc_id             = module.net.vpc_id
  vpc_cidr           = module.net.vpc_cidr
  private_subnet_ids = module.net.private_subnet_ids
  dbuser             = var.dbuser
  dbpassword         = var.dbpassword
}
