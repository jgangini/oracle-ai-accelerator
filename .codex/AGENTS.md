# Local Codex Policy for oracle-ai-accelerator

This file supplements the global `~/.codex/AGENTS.md`.

Keep this file repo-specific. Do not duplicate universal rules that already live in the global policy.

## Project Identity

- Purpose: Oracle AI Accelerator application and its OCI Resource Manager deployment package.
- Technical audience: OCI solution engineers and Deploy Studio maintainers.
- Primary surfaces: application code, `infra/terraform`, and `deploy-studio.json`.

## Repo Operating Defaults

- Preferred validation commands: `python -m unittest discover -s tests -v`, Terraform fmt/init/validate, and the architecture wrappers.
- Preferred search and inspection tools: Semble first; literal `rg` only for exhaustive references.
- Default runtime or environment assumptions: Deploy Studio supplies ephemeral OCI credentials and generated deployment names.

## Local Validation Policy

- Required checks beyond global Graphify and Sentrux: validate `deploy-studio.json` and Terraform without using real credentials.
- Safe shortcuts for docs-only work:
- Release, deploy, or approval gates: never tag or publish a release unless Terraform CI passes.

## Repo-Specific Friction

- Sensitive paths or fragile areas: `infra/terraform/templatefile` bootstraps a live VM and Autonomous Database.
- Credentials, external systems, or approval boundaries: `.oci`, PEM, wallet and state files are local-only; OCI APPLY requires explicit authorization.
- Noisy, slow, or expensive commands to avoid by default:

## Continuous Improvement Triggers

- Promote a repeated friction to this local file after 2 recurrences in the same repo.
- Promote a repeated manual sequence to a script or skill after 3 recurrences or when it is safety-critical.
- Promote a rule to the global policy only when it is cross-repo or clearly universal.
- Review `.codex/improvement-log.md` before large tasks and record only meaningful signal after non-trivial work.

## Future Delegation Hooks

- Candidate explorer roles:
- Candidate reviewer roles:
- Candidate repo-specific skills or MCPs:
