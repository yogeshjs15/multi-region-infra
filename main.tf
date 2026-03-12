provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {
  provider = aws.mumbai
}

################################################
# NETWORKING
################################################

module "networking_mumbai" {
  source = "./modules/networking"

  providers = { aws = aws.mumbai }

  environment          = var.environment
  region               = "ap-south-1"
  region_name          = "mumbai"
  vpc_cidr             = var.vpc_cidr_blocks["ap-south-1"].vpc_cidr
  public_subnet_cidrs  = var.vpc_cidr_blocks["ap-south-1"].public_subnets
  private_subnet_cidrs = var.vpc_cidr_blocks["ap-south-1"].private_subnets
}

module "networking_singapore" {
  source = "./modules/networking"

  providers = { aws = aws.singapore }

  environment          = var.environment
  region               = "ap-southeast-1"
  region_name          = "singapore"
  vpc_cidr             = var.vpc_cidr_blocks["ap-southeast-1"].vpc_cidr
  public_subnet_cidrs  = var.vpc_cidr_blocks["ap-southeast-1"].public_subnets
  private_subnet_cidrs = var.vpc_cidr_blocks["ap-southeast-1"].private_subnets
}

module "networking_tokyo" {
  source = "./modules/networking"

  providers = { aws = aws.tokyo }

  environment          = var.environment
  region               = "ap-northeast-1"
  region_name          = "tokyo"
  vpc_cidr             = var.vpc_cidr_blocks["ap-northeast-1"].vpc_cidr
  public_subnet_cidrs  = var.vpc_cidr_blocks["ap-northeast-1"].public_subnets
  private_subnet_cidrs = var.vpc_cidr_blocks["ap-northeast-1"].private_subnets
}

################################################
# COMPUTE
################################################

module "compute_mumbai" {
  source = "./modules/compute"

  providers = { aws = aws.mumbai }

  environment       = var.environment
  region            = "ap-south-1"
  region_name       = "mumbai"
  vpc_id            = module.networking_mumbai.vpc_id
  public_subnet_ids = module.networking_mumbai.public_subnet_ids

  instance_count = var.instance_count
  instance_type  = var.instance_types[var.environment]
  allowed_ports  = [22, 80]
  ssh_key_name   = var.ssh_key_name
}

module "compute_singapore" {
  source = "./modules/compute"

  providers = { aws = aws.singapore }

  environment       = var.environment
  region            = "ap-southeast-1"
  region_name       = "singapore"
  vpc_id            = module.networking_singapore.vpc_id
  public_subnet_ids = module.networking_singapore.public_subnet_ids

  instance_count = var.instance_count
  instance_type  = var.instance_types[var.environment]
  allowed_ports  = [22, 80]
  ssh_key_name   = var.ssh_key_name
}

module "compute_tokyo" {
  source = "./modules/compute"

  providers = { aws = aws.tokyo }

  environment       = var.environment
  region            = "ap-northeast-1"
  region_name       = "tokyo"
  vpc_id            = module.networking_tokyo.vpc_id
  public_subnet_ids = module.networking_tokyo.public_subnet_ids

  instance_count = var.instance_count
  instance_type  = var.instance_types[var.environment]
  allowed_ports  = [22, 80]
  ssh_key_name   = var.ssh_key_name
}

################################################
# STORAGE
################################################

module "storage" {
  source = "./modules/storage"

  providers = {
    aws.primary = aws.mumbai
    aws.replica = aws.singapore
  }

  environment     = var.environment
  primary_region  = "Mumbai"
  replica_region  = "Singapore"
  bucket_name     = "${var.environment}-mumbai-data-${data.aws_caller_identity.current.account_id}"
}

################################################
# DATABASE
################################################

module "database" {
  source = "./modules/database"

  providers = {
    aws.primary   = aws.mumbai
    aws.replica_1 = aws.singapore
    aws.replica_2 = aws.tokyo
  }

  environment = var.environment
  table_name  = "${var.environment}-global-app-data"
}
