resource "oci_kms_vault" "unseal" {
  compartment_id = var.compartment_ocid
  display_name   = "vault-unseal"
  vault_type     = "DEFAULT"

  # Destroying this makes the sealed Vault data unrecoverable
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_kms_key" "unseal" {
  compartment_id      = var.compartment_ocid
  display_name        = "vault-unseal-key"
  management_endpoint = oci_kms_vault.unseal.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_dynamic_group" "vault" {
  compartment_id = var.tenancy_ocid
  name           = "vault-unseal-dg"
  description    = "Vault host — auto-unseal via OCI KMS instance principals"
  matching_rule  = "ALL {instance.id = '${oci_core_instance.vault.id}'}"
}

resource "oci_identity_policy" "vault_unseal" {
  compartment_id = var.tenancy_ocid
  name           = "vault-unseal-policy"
  description    = "Allow the Vault host to use its KMS key and write backups"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.vault.name} to use keys in compartment id ${var.compartment_ocid} where target.key.id = '${oci_kms_key.unseal.id}'",
    "Allow dynamic-group ${oci_identity_dynamic_group.vault.name} to manage objects in compartment id ${var.compartment_ocid} where target.bucket.name = '${oci_objectstorage_bucket.backups.name}'",
    "Allow dynamic-group ${oci_identity_dynamic_group.vault.name} to read buckets in compartment id ${var.compartment_ocid}",
  ]
}
