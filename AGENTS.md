# Repository Agent Instructions

## Project boundaries

- `infra/terraform` is the Deploy Studio-owned infrastructure package. Keep it directly usable by OCI Resource Manager.
- `deploy-studio.json` is the public deployment contract. Keep its field names aligned with Terraform variables and never declare `source_ref` as a form field.
- Never commit OCI `config`, API private keys, generated SSH keys, wallets, Terraform state, or values derived from them.

## Validation

- Run `./scripts/arch-preflight.ps1` before non-trivial changes and `./scripts/arch-postflight.ps1` afterward.
- Run `python -m unittest discover -s tests -v` for the deployment contract.
- Run `terraform fmt -check -recursive infra/terraform`, then `terraform -chdir=infra/terraform init -backend=false` and `terraform -chdir=infra/terraform validate` with synthetic `.oci` placeholders only.
