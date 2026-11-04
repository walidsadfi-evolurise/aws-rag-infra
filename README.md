# aws-rag-infra

**Terraform for a private RAG API on AWS: VPC with endpoints, ALB (TLS), ECS Fargate with autoscaling and circuit-breaker deployments, RDS PostgreSQL + pgvector (Multi-AZ, encrypted, monitored), S3 for documents, Secrets Manager for everything sensitive, CloudWatch alarms and a dashboard. One module, one example, validated and policy-checked in CI.**

[![CI](https://github.com/walidsadfi-evolurise/aws-rag-infra/actions/workflows/ci.yml/badge.svg)](https://github.com/walidsadfi-evolurise/aws-rag-infra/actions/workflows/ci.yml)
![Terraform 1.6+](https://img.shields.io/badge/terraform-1.6%2B-7B42BC)
![License MIT](https://img.shields.io/badge/license-MIT-green)

*[Version française plus bas](#version-française)*

Built to host [private-rag-kit](https://github.com/walidsadfi-evolurise/private-rag-kit) for clients who want their documents and their index inside their own AWS account, but the module runs any containerised HTTP API that reads `RAG_STORE_URL`-style configuration from the environment.

```
                 ┌──────────────────────────── VPC 10.40.0.0/16 (2–3 AZ) ─────────────────────────────┐
 users ─HTTPS──► │ ALB (public subnets) ──► ECS Fargate service (private subnets)                      │
                 │   TLS 1.3, 80→443        2–6 tasks, CPU target tracking, circuit breaker + rollback  │
                 │                               │              │                 │                    │
                 │                      RDS PostgreSQL 16   S3 documents     Secrets Manager           │
                 │                      pgvector, Multi-AZ  versioned, SSE   DB URL · API token · LLM keys
                 │                      encrypted, PI, EM   TLS-only policy  (ECS secrets injection)   │
                 │  NAT (1 or per-AZ) · VPC endpoints: S3, Secrets Manager, Logs, ECR · flow logs      │
                 │  CloudWatch: 5xx %, unhealthy targets, CPU, DB storage/CPU → SNS (email) · dashboard │
                 └───────────────────────────────────────────────────────────────────────────────────────┘
```

## Use

```hcl
module "rag" {
  source = "github.com/walidsadfi-evolurise/aws-rag-infra//modules/rag-stack?ref=v0.1.0"

  name        = "rag"
  environment = "prod"
  region      = "eu-west-3"
  image       = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/private-rag-kit:0.1.0"

  certificate_arn = aws_acm_certificate.api.arn
  allowed_cidrs   = ["203.0.113.0/24"]          # office / VPN, or 0.0.0.0/0 for a public API

  llm_api_keys = { RAG_ANTHROPIC_API_KEY = var.anthropic_api_key }
  alarm_email  = "ops@example.com"
}
```

Then:

```bash
terraform init && terraform apply
TOKEN=$(aws secretsmanager get-secret-value --secret-id "$(terraform output -raw app_secret_arn)" --query SecretString --output text | jq -r .RAG_API_TOKEN)
curl -s "$(terraform output -raw api_url)/healthz"
```

The [complete example](examples/complete) adds a Route 53 alias and shows how to pass keys through `TF_VAR_…` without ever writing them to disk.

## What the module decides for you

| Area | Choice | Why |
|---|---|---|
| **Network** | Public subnets for the ALB only; tasks and the database are private. Gateway endpoint for S3, interface endpoints for Secrets Manager, Logs and ECR. | Tasks never need a public IP, and most AWS traffic never crosses the NAT gateway (cheaper, no internet dependency for start-up). |
| **Compute** | Fargate, `awsvpc`, read-only root filesystem with a `/tmp` volume, init process, container health check, two IAM roles (execution vs task). | Least privilege by construction: the running code can touch the documents bucket and nothing else. |
| **Deploys** | `minimum_healthy_percent = 100`, circuit breaker with rollback, target-group deregistration delay 15 s. | A bad image never takes the service down; it rolls back on its own. |
| **Scaling** | Target tracking on CPU (60 %), 2→6 tasks by default, slow scale-in. | Simple, predictable; raise `max_count` and add a request-count policy when you know your traffic. |
| **Database** | RDS PostgreSQL 16, gp3, encrypted, Multi-AZ, 7-day backups, Performance Insights, enhanced monitoring, slow-query log, deletion protection. `rag` database and user; the app creates the `vector` extension. | pgvector on RDS is the least operationally expensive vector store for a team that already runs Postgres. |
| **Secrets** | One Secrets Manager secret holding the DSN (URL-encoded password, `sslmode=require`), a generated API token and the LLM keys; injected as ECS secrets by JSON key. | Nothing sensitive in task definitions, state outputs or logs. |
| **Documents** | S3 with versioning, SSE-S3 + bucket keys, public access blocked, TLS-only bucket policy, 90-day expiry of old versions. | A bad re-ingest can be rolled back; nothing is reachable without TLS. |
| **Observability** | Alarms on 5xx rate, unhealthy targets, task CPU, DB storage and CPU → SNS; a dashboard with requests, p50/p95 latency, task and DB metrics. | The four graphs you actually open during an incident. |

Toggles: `single_nat_gateway`, `db_multi_az`, `db_deletion_protection`, `certificate_arn` (empty = HTTP, for dev), `allowed_cidrs`, counts and sizes. Full inputs/outputs: [modules/rag-stack/README.md](modules/rag-stack/README.md).

### Cost ballpark (eu-west-3, prod defaults)

| Component | ~€/month |
|---|---|
| 2 × Fargate 0.5 vCPU / 1 GiB | 35 |
| RDS db.t4g.medium Multi-AZ + 20 GiB gp3 | 120 |
| ALB | 20 + traffic |
| 1 NAT gateway | 35 + traffic |
| 4 interface endpoints | 30 |
| S3, Secrets Manager, CloudWatch | < 10 |
| **Total** | **≈ 250 €** before LLM API usage |

Dev: `db_multi_az = false`, `db.t4g.micro`, `min_count = 1` → ≈ 90 €.

## Quality gates

```bash
make fmt        # terraform fmt -check
make validate   # init -backend=false + validate on the module and the example
make lint       # tflint, recommended preset + AWS ruleset
make security   # checkov with a documented skip list (.checkov.yaml)
make docs       # terraform-docs → modules/rag-stack/README.md
```

CI runs all five on every push, plus a credential-less `terraform plan` of the example to catch provider-level schema errors. Every checkov skip has a one-line reason next to it; review them before adopting the module in a regulated context.

## Roadmap

- [ ] Optional WAF WebACL with the AWS managed rule groups
- [ ] Batch ingestion: a scheduled ECS task that runs `rag ingest s3://…`
- [ ] DB password rotation with a Lambda rotator (needs app-side reconnect)
- [ ] ALB access logs to S3
- [ ] Bedrock as embedder/LLM provider (keeps data in-region, no third-party key)

## License

MIT — see [LICENSE](LICENSE). Built by [Walid Sadfi](https://www.malt.fr/profile/walidsadfi), Forward Deployed Engineer · agents IA & WooCommerce.

---

## Version française

**Terraform pour une API RAG privée sur AWS : VPC avec endpoints, ALB (TLS), ECS Fargate avec autoscaling et déploiements à disjoncteur, RDS PostgreSQL + pgvector (Multi-AZ, chiffré, supervisé), S3 pour les documents, Secrets Manager pour tout ce qui est sensible, alarmes CloudWatch et tableau de bord. Un module, un exemple, validés et contrôlés en CI.**

Conçu pour héberger [private-rag-kit](https://github.com/walidsadfi-evolurise/private-rag-kit) chez des clients qui veulent leurs documents et leur index dans leur propre compte AWS.

- **Réseau** : tâches et base en privé ; endpoints S3, Secrets Manager, Logs, ECR pour éviter la NAT ; flow logs.
- **Compute** : Fargate, système de fichiers en lecture seule, deux rôles IAM (exécution vs tâche), health check conteneur, disjoncteur de déploiement avec retour arrière automatique.
- **Base** : PostgreSQL 16 + pgvector, Multi-AZ, chiffrée, sauvegardes 7 jours, Performance Insights, protection contre la suppression.
- **Secrets** : DSN, token d'API et clés LLM dans un secret, injectés par clé JSON ; rien en clair dans la task definition ni le state.
- **Observabilité** : alarmes 5xx, cibles malsaines, CPU, stockage BDD → SNS ; tableau de bord requêtes / latence p50-p95 / tâches / base.
- **Qualité** : `fmt`, `validate`, `tflint`, `checkov` (liste de contournements commentée), `terraform-docs`, le tout en CI.

Ordre de grandeur : ≈ 250 €/mois en prod par défaut, ≈ 90 € en dev. Un RAG sur vos documents, dans votre compte AWS, avec un point de mesure à 30 jours ? [Parlons-en sur Malt](https://www.malt.fr/profile/walidsadfi).
