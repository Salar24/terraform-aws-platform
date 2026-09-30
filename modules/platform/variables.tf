variable "project" {
  type    = string
  default = "links"
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

# --- Network ---

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type    = number
  default = 3
}

variable "single_nat_gateway" {
  type = bool
}

variable "log_retention_days" {
  type    = number
  default = 30
}

# --- EKS ---

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "eks_public_access_cidrs" {
  type    = list(string)
  default = []
}

variable "eks_admin_principal_arns" {
  type    = list(string)
  default = []
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

# --- Data stores ---

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type = bool
}

variable "db_backup_retention_days" {
  type = number
}

variable "db_deletion_protection" {
  type = bool
}

variable "cache_node_type" {
  type = string
}

variable "cache_node_count" {
  type = number
}
