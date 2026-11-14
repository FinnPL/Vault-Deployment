#!/usr/bin/env bash
# Run a command while SSH to the Vault VM is open for this machine's public IPv4:
#   ./scripts/with-ssh.sh                 log in (ubuntu@vault.cloud.lippok.dev, ~/.ssh/vault_deploy)
#   ./scripts/with-ssh.sh <command...>    e.g. the deploy workflow's ansible-playbook
# SSH is otherwise closed (terraform/network.tf): this adds a rule to the NSG vault-deploy-ssh and removes it
# when the command ends. --clear-stale first drops every rule in that NSG (the workflow: leftovers of an
# aborted run). Needs the OCI CLI with a working config.
set -euo pipefail

host=${VAULT_VM:-vault.cloud.lippok.dev}
key=${VAULT_SSH_KEY:-$HOME/.ssh/vault_deploy}
clear_stale=0
if [[ ${1-} == --clear-stale ]]; then clear_stale=1; shift; fi

# The workflow passes the ID from the Terraform output; the search index can lag behind a new NSG.
nsg=${VAULT_SSH_NSG:-$(oci search resource structured-search \
  --query-text "query networksecuritygroup resources where displayName = 'vault-deploy-ssh'" \
  --query 'data.items[0].identifier' --raw-output)}
if [[ -z $nsg || $nsg == null ]]; then echo "NSG vault-deploy-ssh not found" >&2; exit 1; fi

if ((clear_stale)); then
  stale=$(oci network nsg rules list --nsg-id "$nsg" --all --query 'data[].id' --raw-output)
  if [[ -n $stale && $stale != "[]" && $stale != null ]]; then
    oci network nsg rules remove --nsg-id "$nsg" --security-rule-ids "$stale"
  fi
fi

ip=$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')
rule=$(jq -nc --arg ip "$ip/32" --arg d "with-ssh.sh from $(hostname -s)" \
  '[{direction:"INGRESS",protocol:"6",source:$ip,sourceType:"CIDR_BLOCK",isStateless:false,
     tcpOptions:{destinationPortRange:{min:22,max:22}},description:$d}]')
id=$(oci network nsg rules add --nsg-id "$nsg" --security-rules "$rule" --query 'data."security-rules"[0].id' --raw-output)
trap 'oci network nsg rules remove --nsg-id "$nsg" --security-rule-ids "[\"$id\"]" >/dev/null && echo "SSH closed again"' EXIT
echo "SSH open for $ip"

for _ in $(seq 30); do
  nc -z -w 3 "$host" 22 2>/dev/null && break
  sleep 2
done

if (($#)); then
  "$@"
else
  ssh -i "$key" -o IdentitiesOnly=yes "ubuntu@$host"
fi
