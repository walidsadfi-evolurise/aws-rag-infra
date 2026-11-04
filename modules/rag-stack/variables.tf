variable "name" {
  description = "Base name for every resource (lowercase, hyphens)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name))
    error_message = "name must be 3–31 chars, lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment label used in tags and names (dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region (used for ARNs and endpoints)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the new VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "One NAT gateway for all private subnets (cheaper) instead of one per AZ (more resilient)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------- application
variable "image" {
  description = "Container image for the RAG API (e.g. ghcr.io/walidsadfi-evolurise/private-rag-kit:0.1.0)."
  type        = string
}

variable "container_port" {
  description = "Port the API listens on inside the container."
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate task memory in MiB, compatible with `cpu`."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Baseline number of API tasks."
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Autoscaling floor."
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Autoscaling ceiling."
  type        = number
  default     = 6
}

variable "cpu_target_percent" {
  description = "Target average CPU for autoscaling."
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "Plain (non-secret) environment variables for the API container, e.g. RAG_EMBED_PROVIDER."
  type        = map(string)
  default = {
    RAG_EMBED_PROVIDER = "openai"
    RAG_EMBED_MODEL    = "text-embedding-3-small"
    RAG_LLM_PROVIDER   = "anthropic"
    RAG_LLM_MODEL      = "claude-sonnet-4-5"
    RAG_TOP_K          = "5"
  }
}

variable "llm_api_keys" {
  description = "Secret environment variables injected from Secrets Manager (e.g. { RAG_ANTHROPIC_API_KEY = \"sk-…\" }). Stored encrypted; never appears in task definitions in clear."
  type        = map(string)
  default     = {}
  sensitive   = true
}

# ---------------------------------------------------------------- ingress
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the load balancer. Empty = HTTP only (dev)."
  type        = string
  default     = ""
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to reach the load balancer. Default is the whole internet; restrict to your office/VPN for internal tools."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "ALB health check path."
  type        = string
  default     = "/healthz"
}

# ---------------------------------------------------------------- database
variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB (autoscaling up to max_allocated_storage)."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper bound for RDS storage autoscaling in GiB."
  type        = number
  default     = 200
}

variable "db_engine_version" {
  description = "PostgreSQL major.minor (pgvector needs >= 15.2)."
  type        = string
  default     = "16.4"
}

variable "db_multi_az" {
  description = "Multi-AZ standby for RDS."
  type        = bool
  default     = true
}

variable "db_backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Protect the database from `terraform destroy`."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------- storage & ops
variable "documents_bucket_versioning" {
  description = "Keep versions of uploaded documents."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "alarm_email" {
  description = "Email to subscribe to the alarms topic. Empty = topic without subscription."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}
