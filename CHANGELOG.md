# Changelog

## 0.1.0 — 2026-11-04

- `rag-stack` module: VPC (terraform-aws-modules/vpc) with flow logs and endpoints, ALB with optional TLS, ECS Fargate service with autoscaling and circuit breaker, RDS PostgreSQL 16 for pgvector, S3 documents bucket, Secrets Manager secret with ECS injection, CloudWatch alarms, SNS, dashboard.
- Complete example with Route 53 alias.
- CI: fmt, validate, tflint, checkov, terraform-docs.
