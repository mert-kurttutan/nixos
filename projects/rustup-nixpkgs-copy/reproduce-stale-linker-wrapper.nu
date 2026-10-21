#!/usr/bin/env nu

def fail [message: string] {
  error make { msg: $message }
}

let project_dir = $env.FILE_PWD
let temp_root = (^mktemp -d /tmp/rustup-wrapper-repro.XXXXXX | str trim)
let rustup_home = ($temp_root | path join "rustup")
let cargo_home = ($temp_root | path join "cargo")

print "Building the local rustup flake..."
let build = (^nix build ($project_dir | path join "#rustup") --no-link --print-out-paths | complete)
if $build.exit_code != 0 {
  fail $"nix build failed; temporary files kept at ($temp_root): ($build.stderr)"
}
let rustup_out = ($build.stdout | str trim | lines | last)
let rustup_bin = ($rustup_out | path join "bin" "rustup")

print "Installing stable into an isolated RUSTUP_HOME..."
let install = (with-env { RUSTUP_HOME: $rustup_home, CARGO_HOME: $cargo_home } {
  ^$rustup_bin toolchain install stable --profile minimal | complete
})
if $install.exit_code != 0 {
  fail $"rustup toolchain install failed; temporary files kept at ($temp_root): ($install.stderr)"
}

let wrapper_matches = (glob ($rustup_home | path join "toolchains" "**" "gcc-ld" "ld.lld"))
if ($wrapper_matches | is-empty) {
  fail $"No gcc-ld/ld.lld wrapper found; temporary files kept at ($temp_root)"
}
let wrapper = ($wrapper_matches | first)
let original = (open --raw $wrapper)
let simulated = ($original | str replace --regex '"/nix/store/[^\"]+-rustup-[^\"]+/nix-support/ld-wrapper\.sh"' '"/nix/store/missing-rustup/nix-support/ld-wrapper.sh"')

if $simulated == $original {
  fail $"Could not find the Nix rustup wrapper path in ($wrapper); temporary files kept at ($temp_root)"
}
$simulated | save --force $wrapper

print $"Invoking the isolated wrapper: ($wrapper)"
let result = (with-env { RUSTUP_HOME: $rustup_home, CARGO_HOME: $cargo_home } {
  ^$wrapper --version | complete
})
let output = $result.stderr + $result.stdout
if $result.exit_code == 0 or not ($output | str contains "missing-rustup/nix-support/ld-wrapper.sh") {
  fail $"Expected missing-wrapper failure was not reproduced; temporary files kept at ($temp_root): ($output)"
}

print "PASS: reproduced the missing nix-support/ld-wrapper.sh failure without touching the host rustup installation."
print $"Temporary toolchain was isolated under: ($temp_root)"
print "The temporary directory is retained for inspection; remove it manually when finished."
