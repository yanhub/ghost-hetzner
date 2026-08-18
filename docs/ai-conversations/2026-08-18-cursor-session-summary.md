# Cursor Session Summary — Ghost Hetzner Deploy

Date: 2026-08-18

Tool: Cursor (Composer)

## User Request

Infrastructure task 2:

> Develop one click script to deploy ghost blog platform at a Hetzner VPS with no public SSH access, only through tunnels (any provider/app)

Deliverables: GitHub repository + copies of AI conversations.

## Plan Agreed

1. New repository `ghost-hetzner` (separate from RBAC FastAPI test task)
2. **Tailscale** for tunnel-only SSH (`tailscale up --ssh`)
3. **Hetzner Cloud Firewall** — allow 80/443 only; no port 22
4. **Host UFW** — SSH allowed only on `tailscale0`
5. **Ghost stack** — Docker Compose: Ghost 5 + MySQL 8 + Caddy (HTTPS)
6. **One-click** — `deploy.sh` uses `hcloud` + cloud-init; no public SSH bootstrap

## Implementation Decisions

- Cloud-init embeds compose files and `server-setup.sh` as base64 (no git clone on server needed)
- Public blog remains on 443; assignment targets SSH tunneling, not hiding the blog
- `.env.example` documents all required secrets
- ADRs document Tailscale choice and cloud-init bootstrap pattern

## Files Created

- `deploy.sh` — main entry point
- `scripts/server-setup.sh` — runs on VPS via cloud-init
- `scripts/create-firewall.sh` — Hetzner firewall (80/443)
- `compose/docker-compose.yml`, `compose/Caddyfile`
- `README.md`, `TASK.md`, ADRs, this conversation folder

## Note

This is a **summary**. For submission, attach the full Cursor chat export using the steps in [README.md](README.md).
