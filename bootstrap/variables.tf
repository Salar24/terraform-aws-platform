variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
  default     = "salar24-links-tfstate"
}

variable "github_repository" {
  description = "owner/repo allowed to assume the CI roles."
  type        = string
  default     = "Salar24/terraform-aws-platform"
}

variable "apply_environments" {
  description = "GitHub Environments (with required reviewers) whose jobs may apply."
  type        = list(string)
  default     = ["dev", "prod"]
}
