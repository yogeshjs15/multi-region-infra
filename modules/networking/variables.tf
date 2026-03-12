# modules/networking/variables.tf

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region code"
  type        = string
}

variable "region_name" {
  description = "Friendly region name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}
