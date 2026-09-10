#!/usr/bin/env nu

const source_dir = "/home/kmert/projects/nixos-conf/.agents/skills"

def main [] {
  let home = ($env.HOME? | default "" | path expand)
  if $home == "" {
    error make { msg: "HOME is not set" }
  }

  let codex_home = ($env.CODEX_HOME? | default ($home | path join ".codex") | path expand)
  let target_dir = ($codex_home | path join "skills")

  if not ($source_dir | path exists) {
    error make { msg: $"source skills directory does not exist: ($source_dir)" }
  }

  mkdir $target_dir

  let skills = (glob --no-file ($source_dir | path join "*") | where {|path|
    (($path | path join "SKILL.md") | path exists)
  })

  if ($skills | is-empty) {
    error make { msg: $"no skills containing SKILL.md found in ($source_dir)" }
  }

  for skill_dir in $skills {
    let skill_name = ($skill_dir | path basename)
    let target_skill_dir = ($target_dir | path join $skill_name)

    for source in (glob --no-dir ($skill_dir | path join "**/*")) {
      let relative = ($source | path relative-to $skill_dir)
      let target = ($target_skill_dir | path join $relative)

      mkdir ($target | path dirname)
      cp --no-dereference --force $source $target
    }

    print $"installed ($skill_name) -> ($target_skill_dir)"
  }
}
