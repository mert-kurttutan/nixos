#!/usr/bin/env nu

let script_dir = ($env.CURRENT_FILE | path dirname | path expand)
let target_dir = ($"($env.HOME)/.local/bin" | path expand)

mkdir $target_dir

for source in (glob --no-dir $"($script_dir)/*") {
  let executable = (do { ^test -x $source } | complete)

  if $executable.exit_code != 0 {
    continue
  }

  let name = ($source | path basename)
  let target_name = (
    $name
    | str replace --regex '\.nu$' ''
    | str replace --regex '\.sh$' ''
  )
  let target = ($target_dir | path join $target_name)

  cp --force $source $target
  chmod 755 $target
  print $"installed ($target)"
}

# Keep the Nushell module files importable by the installed `work` command.
# The executable commands above intentionally have their .nu suffix removed;
# these files retain the suffix because `work.nu` imports them by path.
for module in [
  "connect-github-codespace.nu"
  "setup-codespace.nu"
  "prepare-tt.nu"
  "deploy-koyeb-sshd.nu"
] {
  let source = ($script_dir | path join $module)
  let target = ($target_dir | path join $module)
  cp --force $source $target
  print $"installed module ($target)"
}
