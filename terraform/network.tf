resource "oci_core_vcn" "vault" {
  compartment_id = var.compartment_ocid
  display_name   = "vault-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "vault"
}

resource "oci_core_internet_gateway" "vault" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vault.id
  display_name   = "vault-igw"
  enabled        = true
}

resource "oci_core_route_table" "vault" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vault.id
  display_name   = "vault-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vault.id
  }
}

resource "oci_core_security_list" "vault" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vault.id
  display_name   = "vault-sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "SSH"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTP (ACME http-01 + redirect to HTTPS)"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTPS (Caddy -> Vault)"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "vault" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vault.id
  display_name               = "vault-public-subnet"
  cidr_block                 = "10.0.1.0/24"
  route_table_id             = oci_core_route_table.vault.id
  security_list_ids          = [oci_core_security_list.vault.id]
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
}
