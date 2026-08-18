# Infrastructure Task 2 — Ghost on Hetzner (Tunnel-Only SSH)

Deploy the [Ghost](https://ghost.org/) publishing platform to a [Hetzner Cloud](https://www.hetzner.com/cloud) VPS with **no public SSH access**. Administrative access must go through a tunnel (this repo uses [Tailscale](https://tailscale.com/)).

## Deliverables

- [ ] GitHub repository with a one-click deploy script
- [ ] Copies of conversations with AI tools (`docs/ai-conversations/`)

## Requirements

| Requirement | Implementation |
|-------------|----------------|
| Ghost blog platform | Docker: `ghost:5-alpine` + MySQL + Caddy |
| Hetzner VPS | Created via `hcloud` in `deploy.sh` |
| No public SSH | Hetzner firewall (80/443 only) + UFW + Tailscale SSH |
| Tunnel access | Tailscale mesh VPN (`tailscale up --ssh`) |
| One-click deploy | `./deploy.sh` from a configured `.env` |

## Expected Review Flow

1. Clone repo, copy `.env.example` → `.env`
2. Create Hetzner API token and Tailscale auth key
3. Run `./deploy.sh`
4. Verify public blog URL and Tailscale-only SSH

See [README.md](README.md) for full instructions.
