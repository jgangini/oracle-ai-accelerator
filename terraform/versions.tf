terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source = "hashicorp/null"
    }
    oci = {
      source = "oracle/oci"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
