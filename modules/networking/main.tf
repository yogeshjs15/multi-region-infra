# modules/networking/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  provider = aws
  state    = "available"
}

# Create VPC
resource "aws_vpc" "this" {
  provider = aws
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-vpc-${var.region_name}"
    Region      = var.region
    Environment = var.environment
    Component   = "networking"
  }
}

# Create public subnets using count and dynamic AZ selection
resource "aws_subnet" "public" {
  provider = aws
  
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}-${var.region_name}"
    Type = "public"
    AZ   = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  provider = aws
  
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}-${var.region_name}"
    Type = "private"
    AZ   = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "this" {
  provider = aws
  
  vpc_id = aws_vpc.this.id
  
  tags = {
    Name = "${var.environment}-igw-${var.region_name}"
  }
}

# Create Elastic IPs for NAT Gateway (conditional based on environment)
resource "aws_eip" "nat" {
  provider = aws
  
  count = var.environment == "prod" ? length(var.public_subnet_cidrs) : 1
  
  domain = "vpc"
  
  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}-${var.region_name}"
  }
}

# Create NAT Gateways (conditional: multiple for prod, one for others)
resource "aws_nat_gateway" "this" {
  provider = aws
  
  count = var.environment == "prod" ? length(var.public_subnet_cidrs) : 1
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  tags = {
    Name = "${var.environment}-nat-gw-${count.index + 1}-${var.region_name}"
  }
  
  depends_on = [aws_internet_gateway.this]
}

# Create public route table
resource "aws_route_table" "public" {
  provider = aws
  
  vpc_id = aws_vpc.this.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  
  tags = {
    Name = "${var.environment}-public-rt-${var.region_name}"
  }
}

# Create private route tables (multiple for prod with different NAT GWs)
resource "aws_route_table" "private" {
  provider = aws
  
  count = var.environment == "prod" ? length(var.private_subnet_cidrs) : 1
  
  vpc_id = aws_vpc.this.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
  }
  
  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}-${var.region_name}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  provider = aws
  
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  provider = aws
  
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.environment == "prod" ? aws_route_table.private[count.index % length(aws_route_table.private)].id : aws_route_table.private[0].id
}
