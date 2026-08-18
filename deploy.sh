#!/usr/bin/env bash
# One-click Ghost blog deployment on Hetzner Cloud with Tailscale-only SSH access.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

usage() {
  cat <<'EOF'
Usage: ./deploy.sh

Creates a Hetzner VPS, blocks public SSH at the cloud firewall and host UFW,
joins Tailscale for admin SSH, and starts Ghost + MySQL + Caddy via Docker.

Prerequisites:
  - hcloud CLI authenticated (HCLOUD_TOKEN in .env)
  - Tailscale auth key (TAILSCALE_AUTH_KEY in .env)
  - DNS A/AAAA record for your blog domain pointing to the new server IP
  - Copy .env.example to .env and fill in values

After deploy, SSH only works through Tailscale:
  tailscale ssh root@<server-name>

EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy .env.example to .env and configure it." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

required_vars=(
  HCLOUD_TOKEN
  HCLOUD_SERVER_NAME
  TAILSCALE_AUTH_KEY
  GHOST_URL
  MYSQL_ROOT_PASSWORD
  MYSQL_PASSWORD
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Required variable ${var} is empty in ${ENV_FILE}" >&2
    exit 1
  fi
done

HCLOUD_SERVER_TYPE="${HCLOUD_SERVER_TYPE:-cx22}"
HCLOUD_LOCATION="${HCLOUD_LOCATION:-fsn1}"
HCLOUD_IMAGE="${HCLOUD_IMAGE:-ubuntu-24.04}"
ACME_EMAIL="${ACME_EMAIL:-}"
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASSWORD="${SMTP_PASSWORD:-}"
SMTP_FROM="${SMTP_FROM:-Ghost Blog <noreply@example.com>}"

if ! command -v hcloud >/dev/null 2>&1; then
  echo "Install hcloud CLI: https://github.com/hetznercloud/cli#installation" >&2
  exit 1
fi

export HCLOUD_TOKEN

if hcloud server describe "${HCLOUD_SERVER_NAME}" >/dev/null 2>&1; then
  echo "Server '${HCLOUD_SERVER_NAME}' already exists. Delete it first or choose another HCLOUD_SERVER_NAME." >&2
  exit 1
fi

FIREWALL_ID="$("${ROOT_DIR}/scripts/create-firewall.sh")"
CLOUD_INIT_FILE="$(mktemp)"
trap 'rm -f "${CLOUD_INIT_FILE}"' EXIT

encode_file() {
  base64 -w0 "$1"
}

COMPOSE_B64="$(encode_file "${ROOT_DIR}/compose/docker-compose.yml")"
CADDY_B64="$(encode_file "${ROOT_DIR}/compose/Caddyfile")"
SETUP_B64="$(base64 -w0 "${ROOT_DIR}/scripts/server-setup.sh")"

cat > "${CLOUD_INIT_FILE}" <<EOF
#cloud-config
package_update: true
write_files:
  - path: /tmp/ghost-deploy/docker-compose.yml
    encoding: b64
    content: ${COMPOSE_B64}
    permissions: '0644'
  - path: /tmp/ghost-deploy/Caddyfile
    encoding: b64
    content: ${CADDY_B64}
    permissions: '0644'
  - path: /tmp/server-setup.sh
    encoding: b64
    content: ${SETUP_B64}
    permissions: '0755'
  - path: /etc/ghost-deploy.env
    permissions: '0600'
    content: |
      TAILSCALE_AUTH_KEY=${TAILSCALE_AUTH_KEY}
      GHOST_URL=${GHOST_URL}
      MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      MYSQL_PASSWORD=${MYSQL_PASSWORD}
      ACME_EMAIL=${ACME_EMAIL}
      SMTP_HOST=${SMTP_HOST}
      SMTP_PORT=${SMTP_PORT}
      SMTP_USER=${SMTP_USER}
      SMTP_PASSWORD=${SMTP_PASSWORD}
      SMTP_FROM=${SMTP_FROM}
runcmd:
  - [ bash, -lc, "set -a && source /etc/ghost-deploy.env && set +a && /tmp/server-setup.sh > /var/log/ghost-deploy.log 2>&1" ]
EOF

echo "Creating Hetzner server '${HCLOUD_SERVER_NAME}' (${HCLOUD_SERVER_TYPE} @ ${HCLOUD_LOCATION})..."
hcloud server create \
  --name "${HCLOUD_SERVER_NAME}" \
  --type "${HCLOUD_SERVER_TYPE}" \
  --image "${HCLOUD_IMAGE}" \
  --location "${HCLOUD_LOCATION}" \
  --firewall "${FIREWALL_ID}" \
  --user-data-from-file "${CLOUD_INIT_FILE}"

SERVER_IP="$(hcloud server ip "${HCLOUD_SERVER_NAME}")"

cat <<EOF

Deploy started.

Server:   ${HCLOUD_SERVER_NAME}
IPv4:     ${SERVER_IP}
Blog URL: ${GHOST_URL}

Next steps:
1. Point DNS for your domain to ${SERVER_IP}
2. Wait 3-5 minutes for cloud-init (Docker, Tailscale, Ghost)
3. Confirm the node in Tailscale admin: https://login.tailscale.com/admin/machines
4. SSH (Tailscale only — public port 22 is blocked):
     tailscale ssh root@${HCLOUD_SERVER_NAME}
5. Open Ghost setup:
     ${GHOST_URL}/ghost

Logs on the server:
  tail -f /var/log/ghost-deploy.log

EOF
