output "application_url" {
  description = "Oracle AI Accelerator public HTTPS URL."
  value       = "https://${oci_core_instance.linux_instance.public_ip}"
}

output "ssh_user" {
  description = "SSH user for the compute instance."
  value       = "opc"
}

output "adb_db_name" {
  description = "Autonomous Database name used by Oracle AI Accelerator."
  value       = oci_database_autonomous_database.ora26ai.db_name
}

output "autonomous_database_id" {
  description = "Autonomous Database OCID used by Oracle AI Accelerator."
  value       = oci_database_autonomous_database.ora26ai.id
}

output "bucket_name" {
  description = "Object Storage bucket created for Oracle AI Accelerator."
  value       = oci_objectstorage_bucket.bucket.name
}
