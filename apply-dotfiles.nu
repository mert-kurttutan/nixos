#!/usr/bin/env nu

def main [
  --dry-run # Print planned copies without changing files.
] {
  let script_dir = ($env.CURRENT_FILE | path dirname | path expand)
  let dotfiles_dir = ($script_dir | path join dotfiles | path expand)
  let source_root = ($dotfiles_dir | path expand)
  let home = ($env.HOME | path expand)

  for source in (glob --no-dir $"($source_root)/**/*") {
    let relative = ($source | path relative-to $source_root)

    if ($relative | str starts-with "backups/") {
      continue
    }

    let target = ($home | path join $relative)
    let target_dir = ($target | path dirname)

    if $dry_run {
      print $"($source) -> ($target)"
      continue
    }

    mkdir $target_dir

    if ($target | path exists) {
      rm --force $target
    }

    cp $source $target
    print $"installed ($target)"
  }
}
