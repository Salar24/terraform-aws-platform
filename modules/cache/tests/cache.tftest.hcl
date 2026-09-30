mock_provider "aws" {
  mock_resource "aws_elasticache_replication_group" {
    defaults = { primary_endpoint_address = "master.test.abc123.use1.cache.amazonaws.com" }
  }
}

variables {
  name                       = "test"
  vpc_id                     = "vpc-123"
  subnet_ids                 = ["subnet-a", "subnet-b"]
  allowed_security_group_ids = ["sg-eks"]
}

run "single_node_has_no_failover" {
  command = apply

  assert {
    condition     = !aws_elasticache_replication_group.this.automatic_failover_enabled && !aws_elasticache_replication_group.this.multi_az_enabled
    error_message = "Failover requires a replica; must be off for a single node."
  }
}

run "replicas_enable_multi_az_failover" {
  command = apply

  variables {
    node_count = 2
  }

  assert {
    condition     = aws_elasticache_replication_group.this.automatic_failover_enabled && aws_elasticache_replication_group.this.multi_az_enabled
    error_message = "With replicas, automatic failover and Multi-AZ must be on."
  }
}

run "encrypted_and_url_uses_tls" {
  command = apply

  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled && aws_elasticache_replication_group.this.at_rest_encryption_enabled
    error_message = "Cache must be encrypted in transit and at rest."
  }

  assert {
    condition     = output.redis_url == "rediss://master.test.abc123.use1.cache.amazonaws.com:6379/0"
    error_message = "redis_url must use the TLS scheme (rediss://)."
  }
}

run "rejects_zero_nodes" {
  command = plan

  variables {
    node_count = 0
  }

  expect_failures = [var.node_count]
}
