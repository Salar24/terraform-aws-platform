variable "name" {
  description = "Name prefix for all network resources."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. Must be a /16 so it splits into /20 subnets."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && endswith(var.cidr_block, "/16")
    error_message = "cidr_block must be a valid /16 CIDR."
  }
}

variable "az_count" {
  description = "Number of availability zones to span."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 (EKS and RDS need at least 2 AZs)."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, dev) instead of one per AZ (resilient, prod)."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name to tag private subnets for; empty to skip."
  type        = string
  default     = ""
}

variable "flow_logs_retention_days" {
  description = "Retention for VPC flow logs in CloudWatch; 0 disables flow logs."
  type        = number
  default     = 30
}
