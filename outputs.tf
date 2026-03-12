################################################
# VPC OUTPUTS
################################################

output "vpc_ids" {
  value = {
    mumbai    = module.networking_mumbai.vpc_id
    singapore = module.networking_singapore.vpc_id
    tokyo     = module.networking_tokyo.vpc_id
  }
}

################################################
# EC2 OUTPUTS
################################################

output "ec2_public_ips" {
  value = {
    mumbai    = module.compute_mumbai.ec2_public_ips
    singapore = module.compute_singapore.ec2_public_ips
    tokyo     = module.compute_tokyo.ec2_public_ips
  }
}

output "ec2_private_ips" {
  value = {
    mumbai    = module.compute_mumbai.ec2_private_ips
    singapore = module.compute_singapore.ec2_private_ips
    tokyo     = module.compute_tokyo.ec2_private_ips
  }
}

################################################
# S3
################################################

output "s3_primary_bucket" {
  value = module.storage.primary_bucket_id
}

################################################
# DYNAMODB
################################################

output "dynamodb_table_name" {
  value = module.database.global_table_name
}
