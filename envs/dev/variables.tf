variable "eks_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS API (e.g. your office or VPN). Empty = private endpoint only."
  type        = list(string)
  default     = []
}

variable "eks_admin_principal_arns" {
  description = "IAM role ARNs granted cluster-admin (e.g. an SSO admin role)."
  type        = list(string)
  default     = []
}
