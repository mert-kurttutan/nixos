#!/usr/bin/env bash
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo "Unable to detect OS: /etc/os-release is missing." >&2
  exit 1
fi

. /etc/os-release

if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" ]]; then
  echo "This installer is intended for Debian or Ubuntu systems." >&2
  echo "Detected OS ID: ${ID:-unknown}" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo was not found in PATH." >&2
  exit 1
fi

echo "Updating apt package lists..."
sudo apt-get update

echo "Installing repository prerequisites..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

codename="$(lsb_release -sc 2>/dev/null || true)"
if [[ -z "$codename" ]]; then
  codename="${VERSION_CODENAME:-}"
fi

if [[ -z "$codename" ]]; then
  echo "Unable to detect Debian/Ubuntu codename." >&2
  exit 1
fi

echo "Adding deb.griffo.io signing key..."
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg

echo "Adding deb.griffo.io apt repository for ${codename}..."
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt ${codename} main" \
  | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list >/dev/null

echo "Updating apt package lists..."
sudo apt-get update

echo "Installing Nushell..."
sudo apt-get install -y nushell

echo "Nushell installation complete."
