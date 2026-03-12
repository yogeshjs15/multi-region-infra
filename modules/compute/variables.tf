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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ports" {
  description = "List of allowed inbound ports"
  type        = list(number)
  default     = [22, 80]
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}
