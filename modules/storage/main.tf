terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.primary,
        aws.replica
      ]
    }
  }
}
############################################
# STORAGE MODULE – CROSS REGION S3 REPLICATION
############################################

############################################
# Get Account ID
############################################

data "aws_caller_identity" "current" {}

############################################
# PRIMARY BUCKET (Mumbai)
############################################

resource "aws_s3_bucket" "primary" {
  provider = aws.primary

  bucket = var.bucket_name

  tags = {
    Name        = "${var.environment}-primary-bucket-mumbai"
    Environment = var.environment
    Region      = var.primary_region
    Replication = "enabled"
    Component   = "storage"
  }
}

############################################
# PRIMARY BUCKET VERSIONING
############################################

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# PRIMARY BUCKET ENCRYPTION
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# BLOCK PUBLIC ACCESS (PRIMARY)
############################################

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# REPLICA BUCKET (Singapore)
############################################

resource "aws_s3_bucket" "replica" {
  provider = aws.replica

  bucket = "${var.environment}-replica-bucket-singapore-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.environment}-replica-bucket-singapore"
    Environment = var.environment
    Region      = var.replica_region
    Component   = "storage"
  }
}

############################################
# REPLICA VERSIONING (CRITICAL)
############################################

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# REPLICA ENCRYPTION
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# BLOCK PUBLIC ACCESS (REPLICA)
############################################

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# IAM ROLE FOR REPLICATION
############################################

resource "aws_iam_role" "replication" {
  provider = aws.primary

  name = "${var.environment}-s3-replication-role-mumbai"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

############################################
# IAM POLICY FOR REPLICATION
############################################

resource "aws_iam_policy" "replication" {
  provider = aws.primary

  name = "${var.environment}-s3-replication-policy-mumbai"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.primary.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = [
          "${aws_s3_bucket.primary.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = [
          "${aws_s3_bucket.replica.arn}/*"
        ]
      }
    ]
  })
}

############################################
# ATTACH POLICY TO ROLE
############################################

resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.primary
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

############################################
# REPLICATION CONFIGURATION (FIXED ORDER)
############################################

resource "aws_s3_bucket_replication_configuration" "this" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  role     = aws_iam_role.replication.arn

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
    aws_iam_role_policy_attachment.replication
  ]

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}
