data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "vault-backups"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  lifecycle {
    prevent_destroy = true
  }
}
