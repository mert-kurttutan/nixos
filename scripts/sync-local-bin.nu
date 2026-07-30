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
