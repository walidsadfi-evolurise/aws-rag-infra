resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_db_parameter_group" "pg" {
  name_prefix = "${local.name}-pg16-"
  family      = "postgres16"
  description = "pgvector-friendly PostgreSQL settings for ${local.name}"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  # Encryption in transit: refuse plain-text connections (the app's DSN uses sslmode=require).
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_db_instance" "postgres" {
  identifier = local.name

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "rag"
  username = "rag"
  password = random_password.db.result
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az
  parameter_group_name   = aws_db_parameter_group.pg.name

  backup_retention_period   = var.db_backup_retention_days
  backup_window             = "02:00-03:00"
  maintenance_window        = "Sun:03:30-Sun:04:30"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = !var.db_deletion_protection
  final_snapshot_identifier = var.db_deletion_protection ? "${local.name}-final" : null

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = local.tags
}

resource "aws_iam_role" "rds_monitoring" {
  name_prefix        = "${local.name}-rds-mon-"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
