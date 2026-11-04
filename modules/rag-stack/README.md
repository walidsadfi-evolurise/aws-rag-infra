# rag-stack

Terraform module: a production deployment of [private-rag-kit](https://github.com/walidsadfi-evolurise/private-rag-kit) (or any HTTP RAG API) on AWS — VPC, ALB, ECS Fargate with autoscaling, RDS PostgreSQL + pgvector, S3 documents bucket, Secrets Manager, CloudWatch alarms and dashboard.

See the [repository README](../../README.md) for the architecture and the [complete example](../../examples/complete).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.60, < 7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.13 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_"name""></a> ["name"](#input\_"name") | "Base name for every resource (lowercase, hyphens)." | `string` | n/a | yes |
| <a name="input_"environment""></a> ["environment"](#input\_"environment") | "Environment label used in tags and names (dev, staging, prod)." | `string` | `""prod""` | no |
| <a name="input_"region""></a> ["region"](#input\_"region") | "AWS region (used for ARNs and endpoints)." | `string` | n/a | yes |
| <a name="input_"vpc_cidr""></a> ["vpc_cidr"](#input\_"vpc_cidr") | "CIDR for the new VPC." | `string` | `""10.40.0.0/16""` | no |
| <a name="input_"az_count""></a> ["az_count"](#input\_"az_count") | "Number of availability zones to spread subnets across." | `number` | `2` | no |
| <a name="input_"single_nat_gateway""></a> ["single_nat_gateway"](#input\_"single_nat_gateway") | "One NAT gateway for all private subnets (cheaper) instead of one per AZ (more resilient)." | `bool` | `true` | no |
| <a name="input_"image""></a> ["image"](#input\_"image") | "Container image for the RAG API (e.g. ghcr.io/walidsadfi-evolurise/private-rag-kit:0.1.0)." | `string` | n/a | yes |
| <a name="input_"container_port""></a> ["container_port"](#input\_"container_port") | "Port the API listens on inside the container." | `number` | `8000` | no |
| <a name="input_"cpu""></a> ["cpu"](#input\_"cpu") | "Fargate task CPU units (256, 512, 1024, 2048, 4096)." | `number` | `512` | no |
| <a name="input_"memory""></a> ["memory"](#input\_"memory") | "Fargate task memory in MiB, compatible with `cpu`." | `number` | `1024` | no |
| <a name="input_"desired_count""></a> ["desired_count"](#input\_"desired_count") | "Baseline number of API tasks." | `number` | `2` | no |
| <a name="input_"min_count""></a> ["min_count"](#input\_"min_count") | "Autoscaling floor." | `number` | `2` | no |
| <a name="input_"max_count""></a> ["max_count"](#input\_"max_count") | "Autoscaling ceiling." | `number` | `6` | no |
| <a name="input_"cpu_target_percent""></a> ["cpu_target_percent"](#input\_"cpu_target_percent") | "Target average CPU for autoscaling." | `number` | `60` | no |
| <a name="input_"environment_variables""></a> ["environment_variables"](#input\_"environment_variables") | "Plain (non-secret) environment variables for the API container, e.g. RAG_EMBED_PROVIDER." | `map(string)` | <pre>{<br>  "RAG_EMBED_PROVIDER": "\"openai\"",<br>  "RAG_EMBED_MODEL": "\"text-embedding-3-small\"",<br>  "RAG_LLM_PROVIDER": "\"anthropic\"",<br>  "RAG_LLM_MODEL": "\"claude-sonnet-4-5\"",<br>  "RAG_TOP_K": "\"5\""<br>}</pre> | no |
| <a name="input_"llm_api_keys""></a> ["llm_api_keys"](#input\_"llm_api_keys") | "Secret environment variables injected from Secrets Manager (e.g. { RAG_ANTHROPIC_API_KEY = \"sk-…\" }). Stored encrypted; never appears in task definitions in clear." | `map(string)` | <pre>{}</pre> | no |
| <a name="input_"certificate_arn""></a> ["certificate_arn"](#input\_"certificate_arn") | "ACM certificate ARN for HTTPS on the load balancer. Empty = HTTP only (dev)." | `string` | `""""` | no |
| <a name="input_"allowed_cidrs""></a> ["allowed_cidrs"](#input\_"allowed_cidrs") | "CIDRs allowed to reach the load balancer. Default is the whole internet; restrict to your office/VPN for internal tools." | `list(string)` | <pre>[<br>  "\"0.0.0.0/0\""<br>]</pre> | no |
| <a name="input_"health_check_path""></a> ["health_check_path"](#input\_"health_check_path") | "ALB health check path." | `string` | `""/healthz""` | no |
| <a name="input_"db_instance_class""></a> ["db_instance_class"](#input\_"db_instance_class") | "RDS instance class." | `string` | `""db.t4g.medium""` | no |
| <a name="input_"db_allocated_storage""></a> ["db_allocated_storage"](#input\_"db_allocated_storage") | "RDS storage in GiB (autoscaling up to max_allocated_storage)." | `number` | `20` | no |
| <a name="input_"db_max_allocated_storage""></a> ["db_max_allocated_storage"](#input\_"db_max_allocated_storage") | "Upper bound for RDS storage autoscaling in GiB." | `number` | `200` | no |
| <a name="input_"db_engine_version""></a> ["db_engine_version"](#input\_"db_engine_version") | "PostgreSQL major.minor (pgvector needs >= 15.2)." | `string` | `""16.4""` | no |
| <a name="input_"db_multi_az""></a> ["db_multi_az"](#input\_"db_multi_az") | "Multi-AZ standby for RDS." | `bool` | `true` | no |
| <a name="input_"db_backup_retention_days""></a> ["db_backup_retention_days"](#input\_"db_backup_retention_days") | "Automated backup retention." | `number` | `7` | no |
| <a name="input_"db_deletion_protection""></a> ["db_deletion_protection"](#input\_"db_deletion_protection") | "Protect the database from `terraform destroy`." | `bool` | `true` | no |
| <a name="input_"documents_bucket_versioning""></a> ["documents_bucket_versioning"](#input\_"documents_bucket_versioning") | "Keep versions of uploaded documents." | `bool` | `true` | no |
| <a name="input_"log_retention_days""></a> ["log_retention_days"](#input\_"log_retention_days") | "CloudWatch log retention." | `number` | `30` | no |
| <a name="input_"alarm_email""></a> ["alarm_email"](#input\_"alarm_email") | "Email to subscribe to the alarms topic. Empty = topic without subscription." | `string` | `""""` | no |
| <a name="input_"tags""></a> ["tags"](#input\_"tags") | "Extra tags applied to every resource." | `map(string)` | <pre>{}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_"api_url""></a> ["api_url"](#output\_"api_url") | "Base URL of the API (point your DNS CNAME at the load balancer DNS name)." |
| <a name="output_"alb_dns_name""></a> ["alb_dns_name"](#output\_"alb_dns_name") | "Load balancer DNS name." |
| <a name="output_"alb_zone_id""></a> ["alb_zone_id"](#output\_"alb_zone_id") | "Load balancer hosted zone id, for Route 53 alias records." |
| <a name="output_"documents_bucket""></a> ["documents_bucket"](#output\_"documents_bucket") | "S3 bucket for source documents." |
| <a name="output_"app_secret_arn""></a> ["app_secret_arn"](#output\_"app_secret_arn") | "Secrets Manager ARN holding RAG_STORE_URL, RAG_API_TOKEN and LLM keys. Read RAG_API_TOKEN from here to call the API." |
| <a name="output_"db_endpoint""></a> ["db_endpoint"](#output\_"db_endpoint") | "PostgreSQL endpoint (private)." |
| <a name="output_"ecs_cluster_name""></a> ["ecs_cluster_name"](#output\_"ecs_cluster_name") | "ECS cluster name." |
| <a name="output_"ecs_service_name""></a> ["ecs_service_name"](#output\_"ecs_service_name") | "ECS service name (for `aws ecs update-service --force-new-deployment`)." |
| <a name="output_"log_group""></a> ["log_group"](#output\_"log_group") | "CloudWatch log group of the API." |
| <a name="output_"alarms_topic_arn""></a> ["alarms_topic_arn"](#output\_"alarms_topic_arn") | "SNS topic receiving the alarms." |
| <a name="output_"vpc_id""></a> ["vpc_id"](#output\_"vpc_id") | "VPC id." |
| <a name="output_"private_subnets""></a> ["private_subnets"](#output\_"private_subnets") | "Private subnet ids (for extra workloads such as a bastion or batch ingestion)." |
<!-- END_TF_DOCS -->
