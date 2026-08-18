# Cursor Session Summary — Ghost Hetzner Deploy

Date: 2026-08-18  
Tool: Cursor (Composer)  
Language: English (submission copy)

## User Request

Infrastructure task 2:

> Develop one click script to deploy ghost blog platform at a Hetzner VPS with no public SSH access, only through tunnels (any provider/app)

Deliverables: GitHub repository and copies of conversations with AI tools.

## Plan

1. New repository `ghost-hetzner`
2. **Tailscale** for tunnel-only SSH (`tailscale up --ssh`)
3. **Hetzner Cloud Firewall** — allow 80/443 only; no port 22
4. **Host UFW** — SSH allowed only on `tailscale0`
5. **Ghost stack** — Docker Compose: Ghost 5 + MySQL 8 + Caddy (HTTPS)
6. **One-click** — `deploy.sh` uses `hcloud` + cloud-init; no public SSH bootstrap

## Implementation Highlights

- cloud-init embeds compose files and `server-setup.sh` as base64
- Public blog on 443; SSH hardened per assignment scope
- `.env.example` documents required secrets
- Two ADRs document Tailscale and cloud-init choices

## Artifacts

- `deploy.sh`, `scripts/server-setup.sh`, `scripts/create-firewall.sh`
- `compose/docker-compose.yml`, `compose/Caddyfile`
- `README.md`, `TASK.md`, `docs/ai-conversations/`

## Full Export

See [2026-08-18-cursor-ghost-hetzner-full-export.md](2026-08-18-cursor-ghost-hetzner-full-export.md) for the complete English conversation copy.
