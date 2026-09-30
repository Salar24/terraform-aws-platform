# Runs entirely against a mocked AWS provider: no credentials, no cost.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  # The provider still validates ARN formats, so mocks need realistic values.
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:111111111111:log-group:/vpc/test/flow-logs" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test-vpc-flow-logs" }
  }
}

variables {
  name         = "test"
  cluster_name = "test-eks"
}

run "prod_layout_spans_three_azs_with_nat_per_az" {
  command = apply

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3 && length(aws_subnet.data) == 3
    error_message = "Expected 3 public, 3 private and 3 data subnets."
  }

  assert {
    condition     = length(distinct(aws_subnet.private[*].availability_zone)) == 3
    error_message = "Private subnets must be in distinct AZs."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Expected one NAT gateway per AZ when single_nat_gateway = false."
  }

  assert {
    condition     = toset(aws_route.private_nat[*].nat_gateway_id) == toset(aws_nat_gateway.this[*].id)
    error_message = "Each private route table must use its own AZ's NAT gateway."
  }
}

run "dev_layout_shares_one_nat" {
  command = apply

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Expected a single NAT gateway."
  }

  assert {
    condition     = length(distinct(aws_route.private_nat[*].nat_gateway_id)) == 1
    error_message = "All private route tables should share the NAT gateway."
  }
}

run "subnet_cidrs_do_not_overlap" {
  command = plan

  assert {
    condition = length(distinct(concat(
      aws_subnet.public[*].cidr_block,
      aws_subnet.private[*].cidr_block,
      aws_subnet.data[*].cidr_block,
    ))) == 9
    error_message = "Subnet CIDRs must be unique."
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.0.64.0/20" && aws_subnet.data[0].cidr_block == "10.0.128.0/20"
    error_message = "Unexpected subnet CIDR allocation."
  }
}

run "data_subnets_have_no_internet_route" {
  command = apply

  # The only 0.0.0.0/0 routes are on the public and private route tables.
  assert {
    condition = alltrue([
      for id in concat([aws_route.public_internet.route_table_id], aws_route.private_nat[*].route_table_id) :
      id != aws_route_table.data.id
    ])
    error_message = "The data route table must not have a default route."
  }
}

run "subnets_are_tagged_for_kubernetes_load_balancers" {
  command = plan

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.tags["kubernetes.io/role/elb"] == "1"])
    error_message = "Public subnets need the kubernetes.io/role/elb tag."
  }

  assert {
    condition = alltrue([for s in aws_subnet.private :
      s.tags["kubernetes.io/role/internal-elb"] == "1" && s.tags["kubernetes.io/cluster/test-eks"] == "shared"
    ])
    error_message = "Private subnets need internal-elb and cluster tags."
  }
}

run "rejects_single_az" {
  command = plan

  variables {
    az_count = 1
  }

  expect_failures = [var.az_count]
}

run "rejects_non_16_cidr" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/24"
  }

  expect_failures = [var.cidr_block]
}
