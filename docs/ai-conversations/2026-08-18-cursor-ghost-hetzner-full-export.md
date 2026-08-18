# Cursor Conversation Export — Ghost Hetzner Infrastructure Task

Exported: 2026-08-18  
Tool: Cursor (Composer)  
Session: infrastructure task 2 — Ghost on Hetzner with tunnel-only SSH

---

## User

> 2 - infrastructure question task - Develop one click script to deploy ghost blog platform at a Hetzner VPS with no public SSH access, only through tunnels (any provider/app)
>
> We expect a GitHub repository with these tasks completed, along with copies of the conversations with AI tools.

---

## Assistant (plan)

New assignment: one-click Ghost deploy on Hetzner without public SSH.

**Approach chosen:**

1. Separate repo `ghost-hetzner`
2. **Tailscale** for admin SSH (`tailscale up --ssh`)
3. **Hetzner Cloud Firewall** — inbound 80/443 only (no port 22)
4. **Host UFW** — SSH allowed only on `tailscale0`
5. **Ghost stack** — Docker Compose: Ghost 5 + MySQL 8 + Caddy (HTTPS)
6. **One-click** — `deploy.sh` uses `hcloud` + cloud-init (no public SSH bootstrap)

---

## Implementation summary

### Files created

| Path | Purpose |
|------|---------|
| `deploy.sh` | Local one-click: create firewall, VPS, cloud-init |
| `scripts/server-setup.sh` | First-boot: Docker, Tailscale, UFW, Ghost |
| `scripts/create-firewall.sh` | Hetzner firewall (80/443 only) |
| `compose/docker-compose.yml` | Ghost + MySQL + Caddy |
| `compose/Caddyfile` | HTTPS reverse proxy |
| `docs/adr/001-tailscale-ssh-only.md` | ADR: tunnel provider choice |
| `docs/adr/002-cloud-init-one-click.md` | ADR: bootstrap without SSH |
| `README.md`, `TASK.md`, `.env.example` | Docs and configuration template |

### Security model

- Public SSH blocked at Hetzner firewall (no rule for port 22)
- UFW on VPS: `22/tcp` only on `tailscale0`
- Blog served publicly on 443 via Caddy + Let's Encrypt
- Admin: `tailscale ssh root@<HCLOUD_SERVER_NAME>`

### Initial commit

`c92d25e feat: one-click Ghost deploy on Hetzner with Tailscale-only SSH`

---

## User

> да

(Confirming: push to GitHub, export conversation, run real deploy on Hetzner)

---

## Assistant (follow-up)

Executing all three items:

1. Push `ghost-hetzner` to GitHub (`yanhub` org/user from existing remotes)
2. Add this conversation export to `docs/ai-conversations/`
3. Real deploy — requires `.env` with `HCLOUD_TOKEN` and `TAILSCALE_AUTH_KEY`

---

## Notes for reviewers

- This export is reconstructed from the Cursor agent transcript (tool calls redacted).
- For the full raw session, see the Cursor chat export or transcript ID `7ab3fea3-26a1-4f8d-ae07-083778798a7f`.
- RBAC FastAPI task (task 1) lives in a separate repository at `test/`.
