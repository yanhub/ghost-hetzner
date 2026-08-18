#!/usr/bin/env bash
# Creates the GitHub repository and pushes main (requires gh auth or existing remote).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_NAME="${REPO_NAME:-ghost-hetzner}"
GITHUB_OWNER="${GITHUB_OWNER:-yanhub}"

cd "${ROOT_DIR}"

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "git@github.com:${GITHUB_OWNER}/${REPO_NAME}.git"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh repo create "${GITHUB_OWNER}/${REPO_NAME}" \
    --public \
    --source=. \
    --remote=origin \
    --description "One-click Ghost blog on Hetzner with Tailscale-only SSH" \
    --push
  echo "Repository: https://github.com/${GITHUB_OWNER}/${REPO_NAME}"
  exit 0
fi

echo "gh is not authenticated. Create the repo manually, then push:"
echo "  https://github.com/new?name=${REPO_NAME}"
echo "  git push -u origin main"
echo ""
echo "Or run: gh auth login && ./scripts/push-github.sh"

git push -u origin main
