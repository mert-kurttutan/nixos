#!/usr/bin/env nu

# Koyeb CLI setup notes:
# - Official install docs: https://www.koyeb.com/docs/build-and-deploy/cli/installation
# - Official CLI reference: https://www.koyeb.com/docs/build-and-deploy/cli/reference
# - Shell installer for Linux/macOS:
#     curl -fsSL https://raw.githubusercontent.com/koyeb/koyeb-cli/master/install.sh | sh
# - That installer places the binary under ~/.koyeb/bin, so this script calls the
#   discovered absolute path below instead of relying on PATH.
# - Authenticate before deploying:
#     /home/kmert/.koyeb/bin/koyeb login
# - The CLI config defaults to ~/.koyeb.yaml unless KOYEB_CONFIG is set.

let pubkey_file = "/run/media/kmert/kmert-store/credentials/.ssh/koyeb.pub"
let koyeb_bin = "/home/kmert/.koyeb/bin/koyeb"

if not ($koyeb_bin | path exists) {
  print $"koyeb CLI was not found: ($koyeb_bin)"
  exit 1
}

if not ($pubkey_file | path exists) {
  print $"Public key file not found: ($pubkey_file)"
  exit 1
}

let public_key = (open $pubkey_file | str trim)

^$koyeb_bin app init sshd --docker "koyeb/ubuntu-ssh-server" --ports "22:tcp" --proxy-ports "22:tcp" --env $"PUBLIC_KEY=($public_key)" --instance-type "gpu-tenstorrent-n300s" --regions "na" --min-scale 1 --max-scale 1
