############################################
# Creates a PEM (and OpenSSH) formatted private key.
############################################

#https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "instance_ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

############################################
# Data Source: Oracle Linux Image
############################################

#https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images
data "oci_core_images" "oracle_linux" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var._oci_instance.shape.name
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

############################################
# Data Source: Availability Domains
############################################

#https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

############################################
# Compute bootstrap
############################################

locals {
  user_data = templatefile("${path.module}/templatefile/user_data.sh", {
    adb_id             = oci_database_autonomous_database.ora26ai.id
    region             = var.region
    oci_config_base64  = filebase64("${path.module}/.oci/config")
    oci_key_base64     = filebase64("${path.module}/.oci/key.pem")
    source_repo_base64 = base64encode(var.source_repo_url)
    source_ref_base64  = base64encode(var.source_ref)
    source_commit_sha  = var.source_commit_sha
    env_base64 = base64encode(templatefile("${path.module}/templatefile/.env.tmpl", {
      compartment_ocid                       = var.compartment_ocid
      autonomous_database_admin_password     = var.autonomous_database_admin_password
      autonomous_database_db_name            = local.adb_db_name
      autonomous_database_developer_password = var.autonomous_database_developer_password
      autonomous_database_wallet_password    = var.autonomous_database_wallet_password
      namespace                              = var.objectstorage_namespace
      bucket_name                            = oci_objectstorage_bucket.bucket.name
      region                                 = var.region
    }))
  })
}

############################################
# Compute Instance
############################################

#https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
resource "oci_core_instance" "linux_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = var._oci_instance.shape.name

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
    ]
  }

  source_details {
    source_id   = data.oci_core_images.oracle_linux.images[0].id
    source_type = "image"
  }

  shape_config {
    memory_in_gbs = var._oci_instance.shape.memory_in_gbs
    ocpus         = var._oci_instance.shape.ocpus
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    assign_public_ip = true
  }

  display_name = local.instance_display_name

  metadata = {
    ssh_authorized_keys = tls_private_key.instance_ssh.public_key_openssh
    #https://cloudinit.readthedocs.io/en/latest/explanation/format.html
    user_data = base64encode(local.user_data)
  }

}

############################################
# Wait until user_data.sh finishes
############################################

resource "null_resource" "wait_for_userdata" {
  depends_on = [oci_core_instance.linux_instance]

  triggers = {
    instance_id = oci_core_instance.linux_instance.id
  }

  connection {
    type        = "ssh"
    host        = oci_core_instance.linux_instance.public_ip
    user        = "opc"
    private_key = tls_private_key.instance_ssh.private_key_pem
    timeout     = "40m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '[INI] Setup started...............'",
      "timeout 45m sh -c 'until [ -f /var/local/userdata.done ]; do if [ -f /var/local/userdata.failed ]; then exit 1; fi; sleep 5; done' || { echo 'Application bootstrap failed or timed out. Check cloud-init status on the VM.' >&2; exit 1; }",
      "echo ''",
      "cat /home/opc/startup_info.txt | sed 's/\\[PUBLIC-IP\\]/${oci_core_instance.linux_instance.public_ip}/g'",
      "echo ''",
      "echo '[END] Setup completed.............'",
    ]
  }
}
