variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "image" {
  type    = string
  default = "ghcr.io/walidsadfi-evolurise/private-rag-kit:latest"
}

variable "certificate_arn" {
  description = "ACM certificate in the same region; empty for HTTP-only dev."
  type        = string
  default     = ""
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "anthropic_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "openai_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "hosted_zone_id" {
  type    = string
  default = ""
}

variable "api_hostname" {
  type    = string
  default = "api.rag.example.com"
}
