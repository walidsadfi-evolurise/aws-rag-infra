# Everything the API must know but nobody should read lives here, encrypted,
# and reaches the task only through the ECS secrets mechanism.

resource "random_password" "api_token" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name_prefix             = "${local.name}/app-"
  description             = "RAG API runtime secrets: database URL, API token, LLM keys"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode(merge(
    {
      RAG_STORE_URL = "postgresql://${aws_db_instance.postgres.username}:${urlencode(random_password.db.result)}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=require"
      RAG_API_TOKEN = random_password.api_token.result
    },
    local.llm_keys,
  ))
}

locals {
  # Empty values are dropped so an unset provider key does not shadow the app's defaults.
  llm_keys    = { for k, v in var.llm_api_keys : k => v if v != "" }
  secret_keys = concat(["RAG_STORE_URL", "RAG_API_TOKEN"], nonsensitive(keys(local.llm_keys)))
}
