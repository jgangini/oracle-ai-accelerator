# Oracle AI Accelerator Terraform Package

This directory contains the Resource Manager-ready Terraform package that the worker zips per deployment.

## Deploy Studio

Select Oracle AI Accelerator and a validated release. Add the OCI config and API key to see the region and available credits, then choose a new or existing compartment. The region comes from the OCI config. Use the password generator for the database ADMIN, the wallet and the application login. The application username is `admin`.

Deploy Studio passes the selected Git commit to Terraform. The VM checks out that exact commit, then runs database setup and verifies the application health endpoint through Nginx. Manual Terraform deployments can set `source_commit_sha` or use `source_ref` with their own OCI config in `.oci/`.

## Credentials and artifacts

- The OCI API key is required by the current application and Autonomous Database Select AI setup. Deploy Studio adds OCI config and key to the Resource Manager package in memory. The Compute bootstrap and Terraform state contain credentials, and the VM stores the key under the application user's home directory. Use a dedicated, least-privilege test identity and restrict access to the stack, VM and artifacts.
- The wallet is staged in a private Object Storage bucket and removed from the bucket after the VM obtains it. Deploy Studio exports the wallet and VM SSH key as protected artifacts. The repository and the clean source download exclude credential files.
- The application endpoint uses a self-signed HTTPS certificate. Configure a trusted certificate before using it with production credentials or data.
