variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environment label (dev, staging, prod); drives Multi-AZ and deletion protection."
  type        = string
  default     = "prod"
}

variable "image" {
  description = "Container image of the RAG API."
  type        = string
  default     = "ghcr.io/walidsadfi-evolurise/private-rag-kit:latest"
}

variable "certificate_arn" {
  description = "ACM certificate in the same region; empty for HTTP-only dev."
  type        = string
  default     = ""
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "anthropic_api_key" {
  description = "Anthropic API key, passed to the API as RAG_ANTHROPIC_API_KEY. Use TF_VAR_anthropic_api_key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key, passed to the API as RAG_OPENAI_API_KEY. Use TF_VAR_openai_api_key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "alarm_email" {
  description = "E-mail subscribed to the alarms topic (empty = no subscription)."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone id for the API alias record (empty = no DNS record)."
  type        = string
  default     = ""
}

variable "api_hostname" {
  description = "Hostname of the API alias record in the hosted zone."
  type        = string
  default     = "api.rag.example.com"
}
