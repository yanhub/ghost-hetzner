#!/usr/bin/env bash
# Configures a fresh Ubuntu server: Tailscale-only SSH, UFW, Docker, Ghost stack.
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/ghost-blog}"
TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:?TAILSCALE_AUTH_KEY is required}"
GHOST_URL="${GHOST_URL:?GHOST_URL is required}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
ACME_EMAIL="${ACME_EMAIL:-}"
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASSWORD="${SMTP_PASSWORD:-}"
SMTP_FROM="${SMTP_FROM:-Ghost Blog <noreply@example.com>}"

log() {
  echo "[server-setup] $*"
}

export DEBIAN_FRONTEND=noninteractive

log "Installing base packages"
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg ufw jq

log "Installing Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

log "Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --auth-key="${TAILSCALE_AUTH_KEY}" --ssh --accept-routes

log "Locking SSH to Tailscale; keeping HTTP/HTTPS public for the blog"
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp comment 'Ghost HTTP'
ufw allow 443/tcp comment 'Ghost HTTPS'
ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH via Tailscale'
ufw --force enable

log "Hardening sshd: no password auth, no root login"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl reload ssh || systemctl reload sshd

GHOST_DOMAIN="${GHOST_URL#https://}"
GHOST_DOMAIN="${GHOST_DOMAIN#http://}"
GHOST_DOMAIN="${GHOST_DOMAIN%%/*}"

log "Writing Ghost deployment to ${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}/compose"
install -m 0644 /tmp/ghost-deploy/docker-compose.yml "${DEPLOY_DIR}/compose/docker-compose.yml"
install -m 0644 /tmp/ghost-deploy/Caddyfile "${DEPLOY_DIR}/compose/Caddyfile"

cat > "${DEPLOY_DIR}/.env" <<EOF
GHOST_URL=${GHOST_URL}
GHOST_DOMAIN=${GHOST_DOMAIN}
ACME_EMAIL=${ACME_EMAIL}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_FROM=${SMTP_FROM}
EOF
chmod 0600 "${DEPLOY_DIR}/.env"

log "Starting Ghost stack"
docker compose --env-file "${DEPLOY_DIR}/.env" -f "${DEPLOY_DIR}/compose/docker-compose.yml" pull
docker compose --env-file "${DEPLOY_DIR}/.env" -f "${DEPLOY_DIR}/compose/docker-compose.yml" up -d

TAILSCALE_IP="$(tailscale ip -4 | head -n1)"
TAILSCALE_DNS="$(tailscale status --json | jq -r '.Self.DNSName // empty' | sed 's/\.$//')"

log "Setup complete"
log "Tailscale IP: ${TAILSCALE_IP}"
if [[ -n "${TAILSCALE_DNS}" ]]; then
  log "Tailscale SSH: tailscale ssh root@${TAILSCALE_DNS}"
fi
log "Blog URL: ${GHOST_URL}/ghost (complete setup wizard after DNS + HTTPS)"
