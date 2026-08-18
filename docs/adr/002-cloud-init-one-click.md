# ADR 002: Cloud-Init for One-Click Bootstrap Without SSH

## Status

Accepted

## Context

If public SSH is disabled from the start, the first provisioning step cannot rely on `ssh root@<public-ip>`. The deploy script must configure Docker, Tailscale, UFW, and Ghost without interactive access.

## Options Considered

1. **Manual Hetzner console / rescue** — Works once, not one-click.
2. **Packer golden image** — Repeatable but heavy for a test task; image maintenance overhead.
3. **Hetzner cloud-init user-data on server create** — Runs as root on first boot; embeds compose files and setup script via base64.

## Decision

Use **cloud-init** passed through `hcloud server create --user-data-from-file`. The local `deploy.sh` encodes `compose/`, `scripts/server-setup.sh`, and secrets into user-data; `runcmd` executes setup and logs to `/var/log/ghost-deploy.log`.

## Consequences

**Pros:** True one-click from the operator laptop; no chicken-and-egg SSH problem; idempotent enough for assignment scope.

**Cons:** Debugging failed boots requires Hetzner console or Tailscale after partial setup; user-data size limits apply (fine for this stack).

## Trade-offs

Re-running `deploy.sh` creates a new server rather than mutating an existing one, keeping the script simple. Production would add Ansible or Terraform for drift management.
