resource "cloudflare_dns_record" "vault" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "A"
  content = oci_core_instance.vault.public_ip
  ttl     = 300
  proxied = false
}
