# CloudTechNext Terraform Patch Notes

This folder is based on `setup-tf` from:

`https://github.com/jgangini/oracle-ai-accelerator/tree/main/setup-tf`

CloudTechNext keeps the upstream structure and applies a small launchpad layer:

- Parameterized resource names per deployment to support concurrent users.
- Rewrites uploaded OCI `config` so `key_file` points to `/home/opc/.oci/key.pem` inside the target VM.
- Resolves Object Storage namespace in the backend and passes it as a Terraform variable.
- Uses Autonomous AI Database Developer Tier for local validation where ATP TB quota is unavailable.
- Prevents the SSH private key from being uploaded to Object Storage.
- Sanitizes setup SQL output so Resource Manager logs do not expose secrets.
- Uses the application password from the form for the default `admin` app login.
- Normalizes Terraform package line endings to Linux before Resource Manager upload.
- Skips load testing during cloud-init so provisioning focuses on app readiness.
