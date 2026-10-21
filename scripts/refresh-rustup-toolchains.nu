#!/usr/bin/env nu

# Reinstall every rustup-managed toolchain so NixOS linker wrappers are
# regenerated against the currently installed rustup package.
def fail [message: string] {
  error make { msg: $message }
}

def ensure-command [name: string] {
  if (which $name | is-empty) {
    fail $"required command not found: ($name)"
  }
}

def check-result [result: record, operation: string] {
  if $result.exit_code != 0 {
    let details = ($result.stderr | str trim | default ($result.stdout | str trim))
    fail $"($operation) failed: ($details)"
  }
}

export def main [
  --yes(-y) # Skip the confirmation prompt.
] {
  ensure-command rustup

  let listed = (do { ^rustup toolchain list } | complete)
  check-result $listed "rustup toolchain list"

  let toolchains = (
    $listed.stdout
    | lines
    | each {|line| $line | parse -r '^(?<name>\S+)' | get name | first }
    | where {|name| not ($name | is-empty) }
  )

  if ($toolchains | is-empty) {
    fail "rustup has no installed toolchains to refresh"
  }

  print "This will uninstall and reinstall these rustup toolchains:"
  $toolchains | each {|toolchain| print $"  ($toolchain)" }
  print "Extra components and targets will need to be re-added."

  if not $yes {
    let answer = (input "Continue? Type 'refresh' to proceed: ")
    if $answer != "refresh" {
      print "Cancelled."
      return
    }
  }

  for toolchain in $toolchains {
    print $"Removing ($toolchain)..."
    let removed = (do { ^rustup toolchain uninstall $toolchain } | complete)
    check-result $removed $"rustup toolchain uninstall ($toolchain)"
  }

  for toolchain in $toolchains {
    print $"Installing ($toolchain)..."
    let installed = if ($toolchain | str starts-with "stable") {
      do {
        ^rustup toolchain install $toolchain --target wasm32-unknown-unknown --no-self-update
      } | complete
    } else {
      do { ^rustup toolchain install $toolchain --no-self-update } | complete
    }
    check-result $installed $"rustup toolchain install ($toolchain)"
  }

  if ($toolchains | any {|toolchain| $toolchain | str starts-with "stable" }) {
    let selected = (do { ^rustup default stable } | complete)
    check-result $selected "rustup default stable"
  }

  print "Rustup toolchains refreshed."
}
