# Complete example: a production RAG API in eu-west-3 (Paris) with HTTPS,
# Multi-AZ PostgreSQL + pgvector, and e-mail alarms.
#
#   terraform init && terraform plan -var-file=prod.tfvars
#
# Image: build private-rag-kit (github.com/walidsadfi-evolurise/private-rag-kit)
# and push it to ECR or use the public GHCR tag.

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60, < 7.0"
    }
  }

  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "rag/prod/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner = "walid.sadfi@evolurise.com"
    }
  }
}

module "rag" {
  source = "../../modules/rag-stack"

  name        = "rag"
  environment = var.environment
  region      = var.region

  image         = var.image
  desired_count = 2
  min_count     = 2
  max_count     = 6

  certificate_arn = var.certificate_arn
  allowed_cidrs   = var.allowed_cidrs

  db_instance_class      = "db.t4g.medium"
  db_multi_az            = var.environment == "prod"
  db_deletion_protection = var.environment == "prod"

  environment_variables = {
    RAG_EMBED_PROVIDER = "openai"
    RAG_EMBED_MODEL    = "text-embedding-3-small"
    RAG_LLM_PROVIDER   = "anthropic"
    RAG_LLM_MODEL      = "claude-sonnet-4-5"
    RAG_TOP_K          = "5"
  }

  llm_api_keys = {
    RAG_ANTHROPIC_API_KEY = var.anthropic_api_key
    RAG_OPENAI_API_KEY    = var.openai_api_key
  }

  alarm_email = var.alarm_email
}

# Optional DNS: api.rag.example.com → ALB
resource "aws_route53_record" "api" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.api_hostname
  type    = "A"

  alias {
    name                   = module.rag.alb_dns_name
    zone_id                = module.rag.alb_zone_id
    evaluate_target_health = true
  }
}
