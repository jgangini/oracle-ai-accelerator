# Oracle AI Accelerator Terraform Package

This directory contains the Resource Manager-ready Terraform package that the worker zips per deployment.

Runtime rules:

- Deploy Studio injects OCI API `config` and `key.pem` into the in-memory deployment package; they must never be committed.
- Terraform creates the VM SSH key for the current deployment and Deploy Studio exports it only as a protected success artifact.
- Treat Resource Manager state and success artifacts as sensitive because they contain generated credentials.
- Prefer instance principals and least-privilege IAM policies for runtime access.
- Output only non-sensitive IDs and endpoints needed by the portal to collect final artifacts.
