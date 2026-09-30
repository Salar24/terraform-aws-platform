variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Isolated data subnets (no internet route)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 6379."
  type        = list(string)
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "node_count" {
  description = "Total nodes (1 primary + replicas). Use 2+ for automatic failover."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 6
    error_message = "node_count must be between 1 and 6."
  }
}
