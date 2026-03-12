# modules/storage/outputs.tf

output "primary_bucket_id" {
  value = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  value = aws_s3_bucket.primary.arn
}

output "primary_bucket_domain_name" {
  value = aws_s3_bucket.primary.bucket_domain_name
}

output "replica_bucket_id" {
  value = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  value = aws_s3_bucket.replica.arn
}

output "replication_role_arn" {
  value = aws_iam_role.replication.arn
}
