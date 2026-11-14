data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "vault-backups"
  access_type    = "NoPublicAccess"
  # Retention rules and versioning exclude each other
  versioning = "Suspended"

  # Nobody, tenancy admins included, can delete or overwrite a snapshot younger than 30 days.
  retention_rules {
    display_name     = "raft-snapshots-30d"
    time_rule_locked = "2026-11-30T00:00:00Z"
    duration {
      time_amount = 30
      time_unit   = "DAYS"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_policy" "objectstorage_lifecycle" {
  compartment_id = var.tenancy_ocid
  name           = "objectstorage-lifecycle"
  description    = "Allow the Object Storage service to run lifecycle policies"

  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_ocid}",
  ]
}

resource "oci_objectstorage_object_lifecycle_policy" "backups" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.backups.name

  rules {
    name        = "expire-snapshots-after-30d"
    action      = "DELETE"
    is_enabled  = true
    target      = "objects"
    time_amount = 30
    time_unit   = "DAYS"

    object_name_filter {
      inclusion_prefixes = ["raft/"]
    }
  }

  rules {
    name        = "purge-old-versions-after-7d"
    action      = "DELETE"
    is_enabled  = true
    target      = "previous-object-versions"
    time_amount = 7
    time_unit   = "DAYS"
  }

  depends_on = [oci_identity_policy.objectstorage_lifecycle]
}
