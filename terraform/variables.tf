# OCI authentication

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the tenancy."
}

variable "user_ocid" {
  type        = string
  description = "OCID of the user calling the API."
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the API signing key."
}

variable "private_key" {
  type        = string
  sensitive   = true
  description = "PEM contents of the API signing private key."
}

variable "region" {
  type        = string
  default     = "eu-frankfurt-1"
  description = "OCI region."
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to deploy into."
}

# Cloudflare

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token with DNS:Edit on the target zone."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID for the parent zone (e.g. lippok.dev)."
}

variable "domain" {
  type        = string
  default     = "vault.cloud.lippok.dev"
  description = "FQDN that resolves to the Vault host."
}

# Instance / access

variable "ssh_public_key" {
  type        = string
  description = "SSH public key installed for the ubuntu user."
}

variable "instance_ocpus" {
  type        = number
  default     = 2
  description = "OCPUs for the A1.Flex instance (Always Free budget is 4)."
}

variable "instance_memory_gbs" {
  type        = number
  default     = 12
  description = "Memory in GB for the A1.Flex instance (Always Free budget is 24)."
}

variable "instance_boot_volume_gbs" {
  type        = number
  default     = 50
  description = "Boot volume size in GB (Always Free budget is 200 total)."
}
