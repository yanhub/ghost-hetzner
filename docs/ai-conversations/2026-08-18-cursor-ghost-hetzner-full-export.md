# Cursor Conversation Export — Ghost Hetzner Infrastructure Task

Exported: 2026-08-18  
Tool: Cursor (Composer)  
Topic: One-click Ghost blog on Hetzner VPS with tunnel-only SSH

This file is an English copy of the AI-assisted design and implementation session, as required for submission.

---

## User

> infrastructure question task - Develop one click script to deploy ghost blog platform at a Hetzner VPS with no public SSH access, only through tunnels (any provider/app)

---

## Assistant

**Interpretation**

Build a separate repository with a single entry-point script that:

1. Provisions a Hetzner Cloud VPS
2. Deploys Ghost (production-ready, with database and HTTPS)
3. Blocks public SSH; admin access only via a tunnel provider

**Plan**

| Step | Choice |
|------|--------|
| Tunnel / admin access | Tailscale with `tailscale up --ssh` |
| Edge firewall | Hetzner Cloud Firewall — allow TCP 80 and 443 only (no port 22) |
| Host firewall | UFW — SSH allowed only on `tailscale0` |
| Application stack | Docker Compose: Ghost 5 + MySQL 8 + Caddy |
| Bootstrap without SSH | cloud-init user-data on first boot (embed scripts via base64) |
| Public blog | HTTPS on 443 via Caddy + Let's Encrypt |

**Rationale**

- Tailscale fits “any tunnel provider,” supports automated auth keys in cloud-init, and works from macOS/Linux admin machines.
- cloud-init avoids chicken-and-egg: public SSH is never required for provisioning.
- Ghost remains publicly reachable on 443; the assignment targets SSH hardening, not hiding the blog.

---

## Assistant (implementation)

Created repository layout:

```
ghost-hetzner/
├── deploy.sh
├── scripts/server-setup.sh
├── scripts/create-firewall.sh
├── compose/docker-compose.yml
├── compose/Caddyfile
├── docs/adr/
├── docs/ai-conversations/
├── README.md
├── TASK.md
└── .env.example
```

Initial commit: `feat: one-click Ghost deploy on Hetzner with Tailscale-only SSH`

---

## User

> yes

(Confirming: push to GitHub, add conversation export, run a real deploy on Hetzner)

---

## Assistant (follow-up)

**Completed**

1. Added structured conversation export under `docs/ai-conversations/`
2. Added `scripts/push-github.sh` helper
3. Installed `hcloud` CLI on the deployment machine

**Blocked on credentials**

- GitHub: repository must be created on GitHub before the first push (`git push -u origin main`)
- Hetzner deploy: requires `HCLOUD_TOKEN`, `TAILSCALE_AUTH_KEY`, `GHOST_URL`, and MySQL passwords in `.env`

**Deploy steps for reviewer**

```bash
cp .env.example .env
# fill HCLOUD_TOKEN, TAILSCALE_AUTH_KEY, GHOST_URL, MYSQL_* 
chmod +x deploy.sh scripts/*.sh
./deploy.sh
```

After deploy:

```bash
tailscale ssh root@<HCLOUD_SERVER_NAME>
```

---

## Design decisions (from ADRs)

### ADR 001 — Tailscale for tunnel-only SSH

Alternatives considered: manual WireGuard, Cloudflare Tunnel for SSH.  
Decision: Tailscale + Tailscale SSH for simplest one-click bootstrap and cross-platform admin UX.

### ADR 002 — cloud-init for one-click bootstrap

Alternatives considered: manual rescue console, Packer images.  
Decision: Hetzner user-data embeds compose files and `server-setup.sh` so no git clone or public SSH is needed on the server.

---

## Files reference

| File | Role |
|------|------|
| `deploy.sh` | Creates firewall + VPS, passes cloud-init |
| `scripts/create-firewall.sh` | Hetzner firewall (80/443 inbound only) |
| `scripts/server-setup.sh` | First boot: Docker, Tailscale, UFW, Ghost stack |
| `compose/docker-compose.yml` | Ghost + MySQL + Caddy |
| `compose/Caddyfile` | TLS termination and reverse proxy |

---

## Notes for reviewers

- Conversation reconstructed from the Cursor session; tool-call details omitted for readability.
- All project documentation and this export are in English.
- No employer- or client-specific infrastructure names are referenced in this repository.
