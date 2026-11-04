# Security

Report vulnerabilities privately to walid.sadfi@evolurise.com. Acknowledgement within 72 hours.

Operating notes:

- Pass LLM keys through `TF_VAR_…` or a secrets backend; never commit a `.tfvars` with keys (the `.gitignore` excludes `*.tfvars`). The keys end up in the Terraform state: encrypt the state bucket and restrict access to it.
- `allowed_cidrs` defaults to the internet; restrict it for internal tools, or add a WAF.
- The checkov skip list in `.checkov.yaml` documents every deliberate deviation; review it for your compliance context.
