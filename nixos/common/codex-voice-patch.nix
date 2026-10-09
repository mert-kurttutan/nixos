# Temporary NixOS workaround for Codex voice audio. Remove when Codex can
# reliably detect and use the host audio backend, including PipeWire on NixOS.
{ pkgs, codex }:

let
  alsaConfig = pkgs.writeText "codex-pipewire-alsa.conf" ''
    pcm_type.pipewire {
      lib "${pkgs.pipewire}/lib/alsa-lib/libasound_module_pcm_pipewire.so"
    }
    ctl_type.pipewire {
      lib "${pkgs.pipewire}/lib/alsa-lib/libasound_module_ctl_pipewire.so"
    }
    pcm.!default {
      type pipewire
      playback_node -1
      capture_node -1
    }
    ctl.!default { type pipewire }
  '';
in
pkgs.symlinkJoin {
  name = "codex-with-pipewire-audio";
  paths = [ codex ];
  postBuild = ''
    codex="$out/bin/codex"
    mv "$codex" "$codex.nix-upstream"
    cat > "$codex" <<'EOF'
#!/bin/sh
set -eu
codex_dir="''${0%/*}"
export ALSA_CONFIG_PATH="${alsaConfig}"
export ALSA_PLUGIN_DIR="${pkgs.pipewire}/lib/alsa-lib"
export NIX_LD_LIBRARY_PATH="${pkgs.alsa-lib}/lib:/run/current-system/sw/share/nix-ld/lib"
export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
exec "$codex_dir/codex.nix-upstream" "$@"
EOF
    chmod 0755 "$codex"
    sh -n "$codex"
    test -r "${pkgs.pipewire}/lib/alsa-lib/libasound_module_pcm_pipewire.so"
    test -r "${pkgs.pipewire}/lib/alsa-lib/libasound_module_ctl_pipewire.so"
  '';
}
