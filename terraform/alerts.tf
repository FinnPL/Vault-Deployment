resource "oci_ons_notification_topic" "security" {
  compartment_id = var.compartment_ocid
  name           = "vault-security-alerts"
  description    = "Vault unseal key or vault scheduled for deletion or disabled"
}

resource "oci_ons_subscription" "security_email" {
  compartment_id = var.compartment_ocid
  topic_id       = oci_ons_notification_topic.security.id
  protocol       = "EMAIL"
  endpoint       = var.alert_email
}

locals {
  kms_events = ["schedulekeydeletion", "schedulekeyversiondeletion", "schedulevaultdeletion", "disablekey"]
}

resource "oci_events_rule" "unseal_key_deletion" {
  compartment_id = var.compartment_ocid
  display_name   = "vault-unseal-key-deletion"
  description    = "Alert when the KMS key, a key version or the vault is scheduled for deletion or the key is disabled"
  is_enabled     = true
  condition      = jsonencode({ eventType = [for e in local.kms_events : "com.oraclecloud.keymanagementservice.${e}.begin"] })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = oci_ons_notification_topic.security.id
      description = "email"
    }
  }
}

# Created by hand on 2026-11-15 before this file existed.
import {
  to = oci_ons_notification_topic.security
  id = "ocid1.onstopic.oc1.eu-frankfurt-1.amaaaaaa6yzar2aaryuzkcptuyps7kqdmtw6l6uklj5ceidutuf35ernju5a"
}

import {
  to = oci_ons_subscription.security_email
  id = "ocid1.onssubscription.oc1.eu-frankfurt-1.aaaaaaaasxu2uux7dx6aq3jn5kcqyjfgwhrpnmvvenx3friy73jfts6fqpiq"
}

import {
  to = oci_events_rule.unseal_key_deletion
  id = "ocid1.eventrule.oc1.eu-frankfurt-1.amaaaaaa6yzar2aa6xekjvy6qpcngg6vvolpz2c2zsohtrqw3yafuhw2d72a"
}
