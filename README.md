# Vault Deployment

Declarative, GitOps deployment of HashiCorp Vault on an OCI ARM VM.

- **Terraform** — VCN/subnet/security list, A1.Flex VM (2 OCPU / 12 GB, Ubuntu 24.04),
  OCI KMS vault + key for auto-unseal, instance-principal IAM, Cloudflare DNS,
  Object Storage bucket for backups. State lives on OCI Object Storage (S3-compatible).
- **cloud-init** — OS layer only: Docker, OCI CLI, fail2ban, key-only SSH, `/opt/vault`.
- **Ansible** — renders `vault.hcl` + `Caddyfile` from Terraform outputs, installs the
  systemd-managed compose stack and the daily snapshot timer. Gates on
  `cloud-init status --wait`, so the OS and app layers never race.
- **App** — `vault` (raft storage, KMS auto-unseal, mlock) behind `caddy` (Let's Encrypt).

## Prerequisites

1. **State backend:** OCI bucket `vault-tfstate`, a Customer Secret Key.
2. **GitHub secrets**

## Setup

### 1. Initialise Vault (once)
Auto-unseal handles every reboot after this, but init is manual so recovery
material never touches CI logs.

```bash
ssh ubuntu@vault.cloud.lippok.dev
cd /opt/vault
docker compose exec vault vault operator init
```

Store the **recovery keys** and **initial root token** securely.

### 2. Enable audit logging
```bash
export VAULT_ADDR=https://vault.cloud.lippok.dev
vault login <root-token>
vault audit enable file file_path=/vault/file/audit.log
```

### 3. Backups
The `vault-snapshot.timer` runs daily and uploads a raft snapshot to the
`vault-backups` bucket via the instance principal. It needs a token first:

```bash
# create a scoped backup policy + a periodic token, then store it on the host
vault policy write backup - <<'EOF'
path "sys/storage/raft/snapshot" { capabilities = ["read"] }
EOF
vault token create -policy=backup -period=768h -field=token \
  | sudo tee /etc/vault-backup/token >/dev/null
sudo chmod 600 /etc/vault-backup/token

# verify
sudo systemctl start vault-snapshot.service
oci os object list --bucket-name vault-backups --auth instance_principal
```

Restore: `docker compose exec vault vault operator raft snapshot restore <file>`
into a node sealed by the **same** KMS key.

### 4. Root token hygiene
After creating a real auth method + policies, revoke the root token:
`vault token revoke <root-token>` (regenerate later with `operator generate-root`).

### 5. Upgrades
Renovate opens PRs bumping the pinned image tags in `app/docker-compose.yml`.
Merging to `main` re-runs the pipeline; Ansible's `ExecReload` recreates only the
changed container, which reloads raft and auto-unseals.
```
