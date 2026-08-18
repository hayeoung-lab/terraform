output "s3_bucket_name" {
  value = aws_s3_bucket.tfstate.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.locks.name
}
