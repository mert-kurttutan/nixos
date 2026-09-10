#!/usr/bin/env nu

def percent [part: int, total: int] {
  if $total == 0 {
    0.0
  } else {
    (100.0 * $part / $total) | math round --precision 1
  }
}

def input-kind [line: string] {
  let text = ($line | str trim | str lowercase)

  if ($text | str starts-with "#") {
    "ignored"
  } else if ($text | str contains "channels.nixos.org/") and ($text | str contains "/nixexprs.tar.zst") {
    "nixos-zstd"
  } else if ($text | str contains "github:nixos/nixpkgs") or ($text | str contains "github.com/nixos/nixpkgs") {
    "github"
  } else {
    "other"
  }
}

def main [
  directory: string = "." # Root directory to scan recursively.
] {
  let root = ($directory | path expand)
  let files = (
    [($root | path join "flake.nix")]
    | append (glob ($root | path join "**/flake.nix"))
    | where {|file| $file | path exists}
    | uniq
    | sort
  )

  if ($files | is-empty) {
    error make $"No flake.nix files found below ($root)"
  }

  mut rows = []
  for file in $files {
    let counts = (
      open --raw $file
      | lines
      | each { |line| input-kind $line }
      | where {|kind| $kind in [github nixos-zstd]}
      | group-by
      | transpose kind values
      | each {|entry| {kind: $entry.kind count: ($entry.values | length)} }
    )
    let github = (($counts | where kind == github | get count | first) | default 0)
    let zstd = (($counts | where kind == nixos-zstd | get count | first) | default 0)
    let total = $github + $zstd

    $rows = ($rows | append {
      file: ($file | str replace $"($root)/" "")
      github_nixpkgs: $github
      nixos_zstd: $zstd
      recognized: $total
      github_percent: (percent $github $total)
      zstd_percent: (percent $zstd $total)
    })
  }

  let total_github = ($rows | get github_nixpkgs | math sum)
  let total_zstd = ($rows | get nixos_zstd | math sum)
  let total = $total_github + $total_zstd

  print $"Scanned ($files | length) flake.nix files below ($root)."
  print "Only nixpkgs URLs matching the two known conventions are counted."
  print $"Absolute counts: GitHub nixpkgs = ($total_github), NixOS zstd tarballs = ($total_zstd), recognized = ($total)."
  print ""
  print ($rows | table)
  print ""
  print "Overall recognized nixpkgs inputs:"
  print {
    github_nixpkgs: $total_github
    nixos_zstd: $total_zstd
    recognized: $total
    github_percent: (percent $total_github $total)
    zstd_percent: (percent $total_zstd $total)
  }
}
