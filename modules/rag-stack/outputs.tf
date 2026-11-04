output "api_url" {
  description = "Base URL of the API (point your DNS CNAME at the load balancer DNS name)."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.api.dns_name}"
}

output "alb_dns_name" {
  description = "Load balancer DNS name."
  value       = aws_lb.api.dns_name
}

output "alb_zone_id" {
  description = "Load balancer hosted zone id, for Route 53 alias records."
  value       = aws_lb.api.zone_id
}

output "documents_bucket" {
  description = "S3 bucket for source documents."
  value       = aws_s3_bucket.documents.bucket
}

output "app_secret_arn" {
  description = "Secrets Manager ARN holding RAG_STORE_URL, RAG_API_TOKEN and LLM keys. Read RAG_API_TOKEN from here to call the API."
  value       = aws_secretsmanager_secret.app.arn
}

output "db_endpoint" {
  description = "PostgreSQL endpoint (private)."
  value       = aws_db_instance.postgres.address
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name (for `aws ecs update-service --force-new-deployment`)."
  value       = aws_ecs_service.api.name
}

output "log_group" {
  description = "CloudWatch log group of the API."
  value       = aws_cloudwatch_log_group.api.name
}

output "alarms_topic_arn" {
  description = "SNS topic receiving the alarms."
  value       = aws_sns_topic.alarms.arn
}

output "vpc_id" {
  description = "VPC id."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet ids (for extra workloads such as a bastion or batch ingestion)."
  value       = module.vpc.private_subnets
}
