# modules/storage/variables.tf

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "primary_region" {
  description = "Primary region name"
  type        = string
}

variable "replica_region" {
  description = "Replica region name"
  type        = string
}

variable "bucket_name" {
  description = "Primary bucket name"
  type        = string
}
