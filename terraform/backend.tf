# Remote state on OCI Object Storage via its S3-compatible endpoint.
terraform {
  backend "s3" {
    bucket = "vault-tfstate"
    key    = "vault-deployment/terraform.tfstate"
    region = "eu-frankfurt-1"

    endpoints = {
      s3 = "https://frok86tn2y3r.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    }

    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
