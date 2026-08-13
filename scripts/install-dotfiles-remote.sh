#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${NIXOS_CONF_REPO_URL:-https://github.com/mert-kurttutan/nixos.git}"
REPO_REF="${NIXOS_CONF_REPO_REF:-main}"
ZELLIJ_PLUGIN_URL="${ZELLIJ_SIDEBAR_PLUGIN_URL:-https://github.com/mert-kurttutan/zellij-sidebar-plugin/releases/latest/download/vertical-sidebar.wasm}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

need_cmd git
need_cmd curl
need_cmd sed

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

repo_dir="$tmp_dir/nixos-conf"

printf 'cloning %s (%s)\n' "$REPO_URL" "$REPO_REF"
git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$repo_dir"

dotfiles_dir="$repo_dir/dotfiles"
if [ ! -d "$dotfiles_dir" ]; then
  printf 'dotfiles directory not found in cloned repository\n' >&2
  exit 1
fi

printf 'installing dotfiles into %s\n' "$HOME"
while IFS= read -r -d '' source; do
  relative="${source#"$dotfiles_dir"/}"
  target="$HOME/$relative"

  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
  fi

  cp -P "$source" "$target"
  printf 'installed %s\n' "$target"
done < <(
  find "$dotfiles_dir" \( -type f -o -type l \) ! -path "$dotfiles_dir/backups/*" -print0
)

plugin_target="$HOME/.config/zellij/plugins/vertical-sidebar.wasm"
printf 'installing Zellij sidebar plugin into %s\n' "$plugin_target"
mkdir -p "$(dirname "$plugin_target")"
curl --fail --location --silent --show-error --output "$plugin_target" "$ZELLIJ_PLUGIN_URL"

zellij_config="$HOME/.config/zellij/config.kdl"
if [ -f "$zellij_config" ]; then
  escaped_home="$(printf '%s' "$HOME" | sed 's/[\/&|]/\\&/g')"
  sed -i "s|file:/home/kmert/.config/zellij/plugins/vertical-sidebar.wasm|file:${escaped_home}/.config/zellij/plugins/vertical-sidebar.wasm|g" "$zellij_config"
fi

printf 'done\n'
