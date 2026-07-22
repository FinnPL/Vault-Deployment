output "public_ip" {
  description = "Public IP of the Vault host."
  value       = oci_core_instance.vault.public_ip
}

output "domain" {
  value = var.domain
}

output "kms_key_id" {
  description = "OCID of the KMS master key used for auto-unseal."
  value       = oci_kms_key.unseal.id
}

output "kms_crypto_endpoint" {
  value = oci_kms_vault.unseal.crypto_endpoint
}

output "kms_management_endpoint" {
  value = oci_kms_vault.unseal.management_endpoint
}

output "backup_bucket" {
  value = oci_objectstorage_bucket.backups.name
}

output "objectstorage_namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}
