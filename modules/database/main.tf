# modules/database/main.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.primary,
        aws.replica_1,
        aws.replica_2
      ]
    }
  }
}

# Create DynamoDB Global Table with Mumbai as primary
resource "aws_dynamodb_table" "global" {
  provider = aws.primary
  
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"
  
  # Define attributes
  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  }
  
  # Dynamic Global Secondary Indexes based on environment
  dynamic "global_secondary_index" {
    for_each = var.environment == "prod" ? ["GSI1", "GSI2", "GSI3"] : ["GSI1"]
    
    content {
      name            = global_secondary_index.value
      hash_key        = "${global_secondary_index.value}PK"
      range_key       = "${global_secondary_index.value}SK"
      projection_type = "ALL"
    }
  }
  
  # Add attributes for GSIs dynamically
  dynamic "attribute" {
    for_each = var.environment == "prod" ? ["GSI1PK", "GSI1SK", "GSI2PK", "GSI2SK", "GSI3PK", "GSI3SK"] : ["GSI1PK", "GSI1SK"]
    
    content {
      name = attribute.value
      type = "S"
    }
  }
  
  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
  
  # Enable streams for global table
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }
  
  # TTL configuration (optional)
  ttl {
    attribute_name = "TTL"
    enabled        = var.environment == "prod" ? true : false
  }
  
  tags = {
    Name          = var.table_name
    Environment   = var.environment
    PrimaryRegion = "Mumbai"
    Component     = "database"
  }
}

# Create replica in Singapore
resource "aws_dynamodb_table_replica" "singapore" {
  provider = aws.replica_1
  
  global_table_arn = aws_dynamodb_table.global.arn
  
  # Point-in-time recovery for production
  point_in_time_recovery = var.environment == "prod" ? true : false
  
  tags = {
    Name        = "${var.table_name}-singapore-replica"
    Environment = var.environment
    Region      = "Singapore"
  }
}

# Create replica in Tokyo (conditional for production)
resource "aws_dynamodb_table_replica" "tokyo" {
  provider = aws.replica_2
  
  count = var.environment == "prod" ? 1 : 0
  
  global_table_arn = aws_dynamodb_table.global.arn
  
  # Enable point-in-time recovery
  point_in_time_recovery = true
  
  tags = {
    Name        = "${var.table_name}-tokyo-replica"
    Environment = var.environment
    Region      = "Tokyo"
  }
}

# Create sample data item for testing
resource "aws_dynamodb_table_item" "test_item" {
  provider = aws.primary
  
  table_name = aws_dynamodb_table.global.name
  hash_key   = aws_dynamodb_table.global.hash_key
  range_key  = aws_dynamodb_table.global.range_key
  
  item = <<ITEM
{
  "PK": {"S": "CONFIG"},
  "SK": {"S": "REGION#MUMBAI"},
  "Environment": {"S": "${var.environment}"},
  "CreatedAt": {"S": "${timestamp()}"},
  "Settings": {"M": {
    "Replication": {"BOOL": true},
    "BackupEnabled": {"BOOL": ${var.environment == "prod" ? "true" : "false"}}
  }}
}
ITEM
}
