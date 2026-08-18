# ADR 001: Tailscale for Tunnel-Only SSH

## Status

Accepted

## Context

The assignment requires a Hetzner VPS with **no public SSH access**; administration must use a tunnel. We need a solution that works on macOS/Linux admin laptops, is operable in a one-click script, and does not require opening port 22 to the internet.

## Options Considered

1. **WireGuard manually** — Full control, but key distribution and firewall rules are manual; harder to one-click.
2. **Cloudflare Tunnel for SSH** — Possible with `cloudflared access ssh`, but needs Cloudflare account, DNS on Cloudflare, and more moving parts for a blog that may use any DNS provider.
3. **Tailscale + Tailscale SSH** — Mesh VPN with built-in SSH; auth keys automatable in cloud-init; works regardless of DNS provider for the blog.

## Decision

Use **Tailscale** with `tailscale up --auth-key=... --ssh` during cloud-init. Block public SSH at:

- Hetzner Cloud Firewall (no rule for port 22)
- Host UFW (allow 22 only on `tailscale0`)

Public HTTP/HTTPS remain open for Ghost via Caddy.

## Consequences

**Pros:** Simple admin UX (`tailscale ssh root@server`); no public SSH attack surface; well-documented API for auth keys.

**Cons:** Requires Tailscale on admin devices; adds a third-party dependency; blog HTTPS still uses public 80/443 (acceptable for a public blog).

## Trade-offs

We chose Tailscale over Cloudflare Tunnel for SSH because it separates blog DNS (any provider) from admin access and fits the "any tunnel provider" requirement with minimal bootstrap complexity.
