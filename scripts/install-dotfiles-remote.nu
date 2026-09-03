#!/usr/bin/env nu

const default_repo_url = "https://github.com/mert-kurttutan/nixos.git"
const default_repo_ref = "main"
const default_zellij_plugin_url = "https://github.com/mert-kurttutan/zellij-sidebar-plugin/releases/latest/download/vertical-sidebar.wasm"

def main [] {
  need-cmd git
  need-cmd curl

  let repo_url = ($env.NIXOS_CONF_REPO_URL? | default $default_repo_url)
  let repo_ref = ($env.NIXOS_CONF_REPO_REF? | default $default_repo_ref)
  let zellij_plugin_url = ($env.ZELLIJ_SIDEBAR_PLUGIN_URL? | default $default_zellij_plugin_url)
  let home = ($env.HOME | path expand)
  let tmp_dir = (mktemp --directory)
  let repo_dir = ($tmp_dir | path join nixos-conf)

  try {
    print $"cloning ($repo_url) \(($repo_ref)\)"
    git clone --depth 1 --branch $repo_ref $repo_url $repo_dir

    let dotfiles_dir = ($repo_dir | path join dotfiles)
    if not ($dotfiles_dir | path exists) {
      error make { msg: "dotfiles directory not found in cloned repository" }
    }

    install-dotfiles $dotfiles_dir $home
    install-zellij-plugin $zellij_plugin_url $home

    print "done"
  } catch {|err|
    rm --recursive --force $tmp_dir
    error make { msg: $err.msg }
  }

  rm --recursive --force $tmp_dir
}

def need-cmd [cmd: string] {
  if (which $cmd | is-empty) {
    error make { msg: $"missing required command: ($cmd)" }
  }
}

def install-dotfiles [
  dotfiles_dir: path
  home: path
] {
  print $"installing dotfiles into ($home)"

  for source in (glob --no-dir $"($dotfiles_dir)/**/*") {
    let relative = ($source | path relative-to $dotfiles_dir)

    if ($relative | str starts-with "backups/") {
      continue
    }

    let target = ($home | path join $relative)
    let target_dir = ($target | path dirname)

    mkdir $target_dir

    if ($target | path exists) {
      rm --recursive --force $target
    }

    cp --no-dereference $source $target
    print $"installed ($target)"
  }
}

def install-zellij-plugin [
  plugin_url: string
  home: path
] {
  let plugin_target = ($home | path join ".config/zellij/plugins/vertical-sidebar.wasm")
  let plugin_target_dir = ($plugin_target | path dirname)
  let zellij_config = ($home | path join ".config/zellij/config.kdl")
  let expected_plugin_path = "file:/home/kmert/.config/zellij/plugins/vertical-sidebar.wasm"
  let actual_plugin_path = $"file:($home)/.config/zellij/plugins/vertical-sidebar.wasm"

  print $"installing Zellij sidebar plugin into ($plugin_target)"
  mkdir $plugin_target_dir
  curl --fail --location --silent --show-error --output $plugin_target $plugin_url

  if ($zellij_config | path exists) {
    open --raw $zellij_config
    | str replace --all $expected_plugin_path $actual_plugin_path
    | save --force $zellij_config
  }
}
