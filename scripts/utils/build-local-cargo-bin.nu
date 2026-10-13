#!/usr/bin/env nu

# Build the GitHub repository in a temporary checkout and install its release
# binary into ~/.local/bin.

const github_repo = "https://github.com/mert-kurttutan/pdf-process"
const binary_name = "pdf-process"

def run-checked [program: string, args: list<string>, working_dir: path] {
  let result = (
    do { cd $working_dir; run-external $program ...$args } | complete
  )

  if $result.exit_code != 0 {
    let details = (($result.stderr | str trim) | default ($result.stdout | str trim))
    error make { msg: $"($program) failed in ($working_dir): ($details)" }
  }
}

def install-binary [source: path] {
  if not ($source | path exists) {
    error make { msg: $"Built binary was not found: ($source)" }
  }

  let target_dir = ($env.HOME | path join ".local" "bin")
  mkdir $target_dir
  let target = ($target_dir | path join $binary_name)
  cp --force $source $target
  chmod 755 $target
  print $"installed ($target)"
}

def build-from-github [project: path] {
  print $"building ($project) with its flake"
  run-checked "nix" [
    "develop"
    "--accept-flake-config"
    "--command"
    "cargo"
    "build"
    "--release"
    "--locked"
  ] $project

  $project | path join "target" "release" $binary_name
}

def main [] {
  let temp_dir = (^mktemp -d | str trim)

  try {
    let checkout = ($temp_dir | path join $binary_name)
    print $"cloning ($github_repo)"
    run-checked "git" ["clone" "--depth" "1" $github_repo $checkout] $temp_dir

    let built_binary = (build-from-github $checkout)
    install-binary $built_binary
  } catch {|err|
    print --stderr $err.msg
    error make { msg: $err.msg }
  } finally {
    if ($temp_dir | path exists) {
      ^rm -rf $temp_dir
    }
  }
}
