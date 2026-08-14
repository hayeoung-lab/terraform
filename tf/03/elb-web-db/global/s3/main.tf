provider "aws" {
  region = "us-east-2"
}

# S3 버킷 생성하기 + S3 기능 추가 설정
resource "aws_s3_bucket" "myTFState" {
  # 다음은 유일한 값이어야 한다.
  bucket = "bucket-bsc-7979"
  # 다음은 실습용도로만 사용한다.
  force_destroy = true
}

# S3 버킷 - 버전기능 활성화
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.myTFState.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 - 서버측 암호화 방식 선택(SSE|KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.myTFState.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 - Public Access 설정
resource "aws_s3_bucket_public_access_block" "restriced_public_access" {
  bucket                  = aws_s3_bucket.myTFState.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table 생성
resource "aws_dynamodb_table" "myTFLocks" {
  name         = "myTFLocks-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    # type: S(string), N(number), B(binary)
    type = "S"
  }
}

