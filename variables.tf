variable "environment" {
  description = "Environment name (dev / prod)"
  type        = string
}

variable "ssh_key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances per region"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "Instance type per environment"
  type        = map(string)

  default = {
    dev  = "t3.micro"
    prod = "t3.small"
  }
}

variable "vpc_cidr_blocks" {
  description = "CIDR blocks configuration per region"
  type = map(object({
    vpc_cidr       = string
    public_subnets = list(string)
    private_subnets = list(string)
  }))

  default = {
    ap-south-1 = {
      vpc_cidr = "10.0.0.0/16"
      public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
    }

    ap-southeast-1 = {
      vpc_cidr = "10.1.0.0/16"
      public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
    }

    ap-northeast-1 = {
      vpc_cidr = "10.2.0.0/16"
      public_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
      private_subnets = ["10.2.11.0/24", "10.2.12.0/24"]
    }
  }
}
