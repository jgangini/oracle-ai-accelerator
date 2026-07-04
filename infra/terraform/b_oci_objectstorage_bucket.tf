############################################
# Bucket: Creates a bucket in the given namespace with a bucket name
############################################

#https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_bucket
resource "oci_objectstorage_bucket" "bucket" {
  #Required
  compartment_id = var.compartment_ocid
  name           = local.bucket_name
  namespace      = var.objectstorage_namespace

  #Optional
  access_type  = var._oci_bucket_name.access_type
  storage_tier = "Standard"
}
