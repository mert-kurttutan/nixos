#!/usr/bin/env nu

# Koyeb CLI setup notes:
# - Official install docs: https://www.koyeb.com/docs/build-and-deploy/cli/installation
# - Official CLI reference: https://www.koyeb.com/docs/build-and-deploy/cli/reference
# - Shell installer for Linux/macOS:
#     curl -fsSL https://raw.githubusercontent.com/koyeb/koyeb-cli/master/install.sh | sh
# - That installer places the binary under ~/.koyeb/bin, so this script calls the
#   discovered absolute path below instead of relying on PATH.
# - Authenticate before deploying:
#     ~/.koyeb/bin/koyeb login
# - The CLI config defaults to ~/.koyeb.yaml unless KOYEB_CONFIG is set.

export def deploy [] {
  let home = ($env.HOME | path expand)
  let pubkey_file = ($env.KOYEB_PUBKEY_FILE? | default ($home | path join ".ssh" "koyeb.pub") | path expand)
  let koyeb_bin = ($home | path join ".koyeb" "bin" "koyeb")

  if not ($koyeb_bin | path exists) {
    error make { msg: $"koyeb CLI was not found: ($koyeb_bin)" }
  }

  if not ($pubkey_file | path exists) {
    error make { msg: $"Public key file not found: ($pubkey_file)" }
  }

  let public_key = (open $pubkey_file | str trim)

  ^$koyeb_bin app init sshd --docker "koyeb/ubuntu-ssh-server" --ports "22:tcp" --proxy-ports "22:tcp" --env $"PUBLIC_KEY=($public_key)" --instance-type "gpu-tenstorrent-n300s" --regions "na" --min-scale 1 --max-scale 1
}

export def main [] {
  deploy
}

export alias koyeb-deploy = main
