locals {
  bucket_name           = var.bucket_name != "" ? var.bucket_name : "buk-oracle-ai-${var.deployment_suffix}"
  adb_db_name           = var.adb_db_name != "" ? var.adb_db_name : substr("oraai${var.deployment_suffix}", 0, 14)
  adb_display_name      = var.adb_display_name != "" ? var.adb_display_name : "ora26ai-${var.deployment_suffix}"
  vcn_display_name      = var.vcn_display_name != "" ? var.vcn_display_name : "vcn-oracle-ai-${var.deployment_suffix}"
  instance_display_name = var.instance_display_name != "" ? var.instance_display_name : "oracle-linux-9-app-${var.deployment_suffix}"
}
