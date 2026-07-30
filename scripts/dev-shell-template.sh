#!/usr/bin/env bash
set -e

# ----------------------------
# Configuration (defaults)
# ----------------------------
GCROOT=true
PROFILE_PATH="dev.nix-cache"
TRACK_FLAKE=false

# ----------------------------
# Argument parsing
# ----------------------------
for arg in "$@"; do
  case "$arg" in
    --no-gcroot) GCROOT=false ;;
    --gcroot) GCROOT=true ;;
    --track-flake|-t) TRACK_FLAKE=true ;;
    -h|--help)
      cat <<'HELP'
Usage: dev-shell-template [options]

Options:
  --gcroot        Prime a nix develop profile GC-root (default)
  --no-gcroot     Do not create/prime the profile GC-root
  --track-flake   Run "git add -N flake.nix" before nix develop
                  Do not run git tracking (default)
  -h, --help      Show this help

Behavior:
  - Always creates ./flake.nix in the current directory
  - With --track-flake, ensures flake.nix is tracked in git repos
  - If --gcroot is enabled, runs:
      nix develop --profile .nix-develop-cache --command true
  - Does NOT enter/activate the dev shell afterwards
HELP
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Use --help for usage"
      exit 1
      ;;
  esac
done

# ----------------------------
# UI helpers
# ----------------------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Nix Development Environment Creator   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Creating flake.nix...${NC}"

# ----------------------------
# flake.nix generation
# ----------------------------
cat > flake.nix << 'EOF'
{
  description = "Development environment with custom prompt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dev_env_name = "dev";
      in
      {
        devShells.default = pkgs.mkShell {
          SHELL = "${pkgs.bashInteractive}/bin/bash";

          # 👇 Add your development packages here
          buildInputs = with pkgs; [
            bashInteractive
            # add packages here
          ];

          shellHook = ''
            export SHELL="${pkgs.bashInteractive}/bin/bash"

            if [[ $- == *i* ]]; then
              export PS1='\[\e[32m\][\u@\h:\w]\[\e[0m\]\n\[\e[36m\](${dev_env_name})\[\e[0m\] \[\e[32m\]>\[\e[0m\] '
              echo "🚀 Welcome to ${dev_env_name} environment!"
              echo ""
            fi
          '';
        };
      }
    );
}
EOF

echo -e "${GREEN}✓ flake.nix created successfully!${NC}"
echo ""

# ----------------------------
# Optional: track flake.nix in git repo to avoid nix errors
# ----------------------------
if [[ "$TRACK_FLAKE" == "true" ]]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add -N flake.nix
    echo -e "${GREEN}✓ flake.nix marked as tracked in git${NC}"
    echo ""
  else
    echo -e "${YELLOW}Skipping git tracking (not a git repo).${NC}"
    echo ""
  fi
fi

# ----------------------------
# Optional: prime GC root profile (no interactive shell)
# ----------------------------
if [[ "$GCROOT" == "true" ]]; then
  echo -e "${GREEN}Priming nix develop GC root profile...${NC}"
  nix develop --profile "$PROFILE_PATH" --command true
  echo -e "${GREEN}✓ Profile created/updated:${NC} ${YELLOW}${PROFILE_PATH}${NC}"
  echo ""
fi

# ----------------------------
# Instructions (no activation)
# ----------------------------
echo -e "${CYAN}Next steps:${NC}"
echo -e "  ${YELLOW}1.${NC} Edit flake.nix and add packages"
echo -e "  ${YELLOW}2.${NC} Enter the environment when you want:"
echo -e "     ${YELLOW}nix develop --profile ${PROFILE_PATH}${NC}"
echo ""
