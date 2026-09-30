mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:111111111111:key/test" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test" }
  }
  mock_resource "aws_launch_template" {
    defaults = { id = "lt-0123456789abcdef0", latest_version = 1 }
  }
}

variables {
  name       = "test"
  subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
}

run "cluster_is_hardened_by_default" {
  command = apply

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access == false
    error_message = "API endpoint should be private when no public CIDRs are given."
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API"
    error_message = "Cluster should use access entries, not the aws-auth ConfigMap."
  }

  assert {
    condition     = contains(aws_eks_cluster.this.encryption_config[0].resources, "secrets")
    error_message = "Kubernetes Secrets must be envelope-encrypted with KMS."
  }

  assert {
    condition     = aws_kms_key.eks.enable_key_rotation
    error_message = "KMS key rotation must be enabled."
  }

  assert {
    condition     = contains(aws_eks_cluster.this.enabled_cluster_log_types, "audit")
    error_message = "Audit logging must be enabled."
  }
}

run "nodes_block_pod_access_to_instance_metadata" {
  command = apply

  assert {
    condition     = aws_launch_template.node.metadata_options[0].http_tokens == "required"
    error_message = "Nodes must require IMDSv2."
  }

  assert {
    condition     = aws_launch_template.node.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "Hop limit must be 1 so pods can't use the node's IAM role."
  }

  assert {
    condition     = aws_launch_template.node.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "Node volumes must be encrypted."
  }
}

run "vpc_cni_enforces_network_policies" {
  command = apply

  assert {
    condition     = jsondecode(aws_eks_addon.this["vpc-cni"].configuration_values).enableNetworkPolicy == "true"
    error_message = "VPC CNI must enforce NetworkPolicy (the app chart depends on it)."
  }

  assert {
    condition     = contains(keys(aws_eks_addon.this), "eks-pod-identity-agent")
    error_message = "Pod Identity agent add-on is required for workload IAM."
  }
}

run "public_endpoint_limited_to_given_cidrs" {
  command = apply

  variables {
    public_access_cidrs = ["203.0.113.0/24"]
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access && tolist(aws_eks_cluster.this.vpc_config[0].public_access_cidrs) == ["203.0.113.0/24"]
    error_message = "Public endpoint should be enabled only for the listed CIDRs."
  }
}

run "rejects_api_open_to_internet" {
  command = plan

  variables {
    public_access_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.public_access_cidrs]
}

run "rejects_single_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-a"]
  }

  expect_failures = [var.subnet_ids]
}
