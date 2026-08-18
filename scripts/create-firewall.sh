#!/usr/bin/env bash
# Creates a Hetzner Cloud firewall allowing only HTTP/HTTPS (no public SSH).
set -euo pipefail

HCLOUD_TOKEN="${HCLOUD_TOKEN:?HCLOUD_TOKEN is required}"
FIREWALL_NAME="${FIREWALL_NAME:-ghost-blog-fw}"

if ! command -v hcloud >/dev/null 2>&1; then
  echo "hcloud CLI is required: https://github.com/hetznercloud/cli" >&2
  exit 1
fi

export HCLOUD_TOKEN

existing_id="$(hcloud firewall list -o noheader -o columns=id,name | awk -v name="${FIREWALL_NAME}" '$2 == name { print $1; exit }')"

if [[ -n "${existing_id}" ]]; then
  echo "${existing_id}"
  exit 0
fi

hcloud firewall create --name "${FIREWALL_NAME}" >/dev/null

hcloud firewall add-rule "${FIREWALL_NAME}" --direction in --protocol tcp --port 80 \
  --source-ips 0.0.0.0/0 --source-ips ::/0 --description "HTTP"
hcloud firewall add-rule "${FIREWALL_NAME}" --direction in --protocol tcp --port 443 \
  --source-ips 0.0.0.0/0 --source-ips ::/0 --description "HTTPS"

hcloud firewall list -o noheader -o columns=id,name | awk -v name="${FIREWALL_NAME}" '$2 == name { print $1; exit }'
