#!/usr/bin/env nu

def fail [message: string] {
  error make { msg: $message }
}

let project_dir = $env.FILE_PWD
let temp_root = (^mktemp -d /tmp/rustup-wrapper-repro.XXXXXX | str trim)
let rustup_home = ($temp_root | path join "rustup")
let cargo_home = ($temp_root | path join "cargo")

print "Building the local rustup flake..."
let flake_ref = ($project_dir | str replace --regex '/$' '') + "#rustup"
let build = (^nix build $flake_ref --no-link --print-out-paths | complete)
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
if not ($original | str contains "rustup-ld-wrapper") {
  fail $"Generated launcher does not call rustup-ld-wrapper: ($wrapper); temporary files kept at ($temp_root)"
}
if ($original | str contains "nix-support/ld-wrapper.sh") {
  fail $"Generated launcher still embeds a path to nix-support/ld-wrapper.sh: ($wrapper)"
}

let stale_wrapper = ($temp_root | path join "stale-ld.lld")
let stale_script = "#!/usr/bin/env bash\nexec /nix/store/missing-rustup/nix-support/ld-wrapper.sh \"$@\"\n"
$stale_script | save --force $stale_wrapper
^chmod +x $stale_wrapper
let stale_result = (^$stale_wrapper --version | complete)
let stale_output = $stale_result.stderr + $stale_result.stdout
if $stale_result.exit_code == 0 or not ($stale_output | str contains "missing-rustup/nix-support/ld-wrapper.sh") {
  fail $"Could not reproduce the stale store-path failure; temporary files kept at ($temp_root): ($stale_output)"
}

let rustup_bin_dir = ($rustup_out | path join "bin")
print "Invoking the fixed linker wrapper via the current package's bin directory on PATH..."
let result = (with-env { RUSTUP_HOME: $rustup_home, CARGO_HOME: $cargo_home, PATH: ($env.PATH | prepend $rustup_bin_dir) } {
  ^$wrapper --version | complete
})
if $result.exit_code != 0 {
  fail $"Fixed linker wrapper failed; temporary files kept at ($temp_root): ($result.stderr)"
}

let source = ($temp_root | path join "main.rs")
let binary = ($temp_root | path join "hello")
'fn main() {}' | save --force $source
let compile = (with-env { RUSTUP_HOME: $rustup_home, CARGO_HOME: $cargo_home, PATH: ($env.PATH | prepend $rustup_bin_dir) } {
  ^$rustup_bin run stable rustc $source -o $binary | complete
})
if $compile.exit_code != 0 {
  fail $"Rust link smoke test failed; temporary files kept at ($temp_root): ($compile.stderr)"
}

print "PASS: stale-path failure reproduced; fixed wrapper and Rust link smoke test succeeded."
print $"Temporary toolchain was isolated under: ($temp_root)"
print "The temporary directory is retained for inspection; remove it manually when finished."
