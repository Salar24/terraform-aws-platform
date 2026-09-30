mock_provider "aws" {}

variables {
  name                       = "test"
  vpc_id                     = "vpc-123"
  subnet_ids                 = ["subnet-a", "subnet-b"]
  allowed_security_group_ids = ["sg-eks"]
}

run "production_settings" {
  command = apply

  variables {
    multi_az            = true
    deletion_protection = true
  }

  assert {
    condition     = aws_db_instance.this.multi_az && aws_db_instance.this.deletion_protection
    error_message = "Prod database must be Multi-AZ with deletion protection."
  }

  assert {
    condition     = !aws_db_instance.this.skip_final_snapshot && aws_db_instance.this.final_snapshot_identifier == "test-final"
    error_message = "Protected databases must take a final snapshot."
  }
}

run "never_public_always_encrypted" {
  command = apply

  assert {
    condition     = !aws_db_instance.this.publicly_accessible && aws_db_instance.this.storage_encrypted
    error_message = "Database must be private and encrypted at rest."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "Master password must be managed by RDS in Secrets Manager, not Terraform."
  }

  assert {
    condition = anytrue([
      for p in aws_db_parameter_group.this.parameter : p.name == "rds.force_ssl" && p.value == "1"
    ])
    error_message = "Connections must require TLS."
  }
}

run "only_allowed_security_groups_can_connect" {
  command = apply

  variables {
    allowed_security_group_ids = ["sg-eks", "sg-bastion"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.postgres) == 2
    error_message = "Expected one ingress rule per allowed security group."
  }

  assert {
    condition = alltrue([
      for r in aws_vpc_security_group_ingress_rule.postgres :
      r.from_port == 5432 && r.to_port == 5432 && r.cidr_ipv4 == null
    ])
    error_message = "Ingress must be port 5432 from security groups only, never CIDR ranges."
  }
}

run "dev_can_be_destroyed_cleanly" {
  command = apply

  variables {
    deletion_protection = false
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot
    error_message = "Unprotected (dev) databases should skip the final snapshot."
  }
}

run "rejects_disabled_backups" {
  command = plan

  variables {
    backup_retention_days = 0
  }

  expect_failures = [var.backup_retention_days]
}
