# modules/database/outputs.tf

output "global_table_arn" {
  value = aws_dynamodb_table.global.arn
}

output "global_table_name" {
  value = aws_dynamodb_table.global.name
}

output "global_table_stream_arn" {
  value = aws_dynamodb_table.global.stream_arn
}

output "singapore_replica_arn" {
  value = aws_dynamodb_table_replica.singapore.arn
}

output "tokyo_replica_arn" {
  value = var.environment == "prod" ? aws_dynamodb_table_replica.tokyo[0].arn : null
}
