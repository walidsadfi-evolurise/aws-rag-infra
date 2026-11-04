.PHONY: fmt validate lint security docs check

fmt:
	terraform fmt -recursive -check -diff

validate:
	cd modules/rag-stack && terraform init -backend=false -input=false >/dev/null && terraform validate
	cd examples/complete && terraform init -backend=false -input=false >/dev/null && terraform validate

lint:
	tflint --init >/dev/null && tflint --recursive --config "$(CURDIR)/.tflint.hcl"

security:
	checkov --config-file .checkov.yaml

docs:
	terraform-docs markdown table --output-file README.md --output-mode inject modules/rag-stack

check: fmt validate lint security
