locals {
  name = "${var.name}-${var.environment}"

  tags = merge(
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws-rag-infra/rag-stack"
    },
    var.tags,
  )

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 10 + i)]
  db_subnets      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 20 + i)]

  https_enabled = var.certificate_arn != ""
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
