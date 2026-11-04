output "api_url" {
  value = module.rag.api_url
}

output "documents_bucket" {
  value = module.rag.documents_bucket
}

output "app_secret_arn" {
  value = module.rag.app_secret_arn
}

output "first_call" {
  description = "How to make the first request once the service is healthy."
  value       = <<-EOT
    TOKEN=$(aws secretsmanager get-secret-value --secret-id ${module.rag.app_secret_arn} --query SecretString --output text | jq -r .RAG_API_TOKEN)
    curl -s ${module.rag.api_url}/healthz
    curl -s -X POST ${module.rag.api_url}/ask -H "Authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"question":"…"}'
  EOT
}
