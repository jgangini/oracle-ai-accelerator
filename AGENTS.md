# Repository Agent Instructions

## Project boundaries

- The root `terraform/` directory is the Deploy Studio-owned infrastructure package. Keep it directly usable by OCI Resource Manager.
- `terraform/deploy-studio.json` is the public deployment contract. Keep its field names aligned with Terraform variables and never declare `source_ref` as a form field.
- Never commit OCI `config`, API private keys, generated SSH keys, wallets, Terraform state, or values derived from them.

## Validation

- Run `./scripts/arch-preflight.ps1` before non-trivial changes and `./scripts/arch-postflight.ps1` afterward.
- Run `python -m unittest discover -s tests -v` for the deployment contract.
- Run `terraform fmt -check -recursive terraform`, then `terraform -chdir=terraform init -backend=false` and `terraform -chdir=terraform validate` with synthetic `.oci` placeholders only.
