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

echo "Removing the paid deb.griffo.io repository, if present..."
sudo rm -f \
  /etc/apt/sources.list.d/deb.griffo.io.list \
  /etc/apt/keyrings/deb.griffo.io.gpg

echo "Adding the public Nushell repository signing key..."
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://apt.fury.io/nushell/gpg.key \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/fury-nushell.gpg

echo "Adding the public Nushell apt repository..."
echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" \
  | sudo tee /etc/apt/sources.list.d/fury-nushell.list >/dev/null

echo "Updating apt package lists..."
sudo apt-get update

echo "Installing Nushell..."
sudo apt-get install -y nushell

echo "Nushell installation complete."
