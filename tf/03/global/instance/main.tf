terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "bucket-2001-0104"   # ①에서 만든 버킷 이름과 동일하게
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "state-test-intance" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t3.micro"   # 원본은 t2.micro, 프리티어 에러 방지로 t3.micro 권장

  tags = {
    Name = "state-test-instance"
  }
}
