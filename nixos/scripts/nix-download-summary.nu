#!/usr/bin/env nu

def mib [bytes: int] {
  (($bytes | into float) / 1024.0 / 1024.0) | math round --precision 1
}

def store_name [path: string] {
  $path | path basename | str replace --regex '^[a-z0-9]{32}-' ''
}

def store_hash [path: string] {
  $path | path basename | str substring 0..31
}

def narinfo_filesize [cache: string, path: string] {
  let hash = (store_hash $path)
  let url = $"($cache)/($hash).narinfo"
  let response = (do { ^curl --fail --silent --show-error $url } | complete)

  if $response.exit_code != 0 {
    return 0
  }

  let line = (
    $response.stdout
    | lines
    | where { |line| $line =~ '^FileSize: ' }
    | first
  )

  if ($line | is-empty) {
    0
  } else {
    $line | str replace 'FileSize: ' '' | into int
  }
}

def print_why_depends [installable: string, row: record] {
  print ""
  print $"# ($row.name) - ($row.download_mib) MiB"
  print $row.path

  let why = (do {
    nix why-depends --derivation $installable $row.path
  } | complete)

  if $why.exit_code == 0 {
    print ($why.stdout | str trim)
  } else {
    print ($why.stderr | str trim)
  }
}

def main [
  --flake: string = "./nixos" # Flake directory, relative to where you run the script.
  --config: string = "nixos" # nixosConfigurations.<name>.
  --top: int = 30 # Number of largest download entries to show.
  --cache: string = "https://cache.nixos.org" # Binary cache to query for NAR sizes.
  --threads: int = 32 # Parallel .narinfo requests for compressed download sizes.
  --why # Show nix why-depends --derivation for each displayed path row.
] {
  let installable = $"($flake)#nixosConfigurations.($config).config.system.build.toplevel"

  print $"Dry-running ($installable) ..."
  let dry = (do { nix build --dry-run $installable } | complete)
  let dry_output = [$dry.stdout $dry.stderr] | str join "\n"

  if $dry.exit_code != 0 {
    print $dry_output
    error make {
      msg: $"nix build --dry-run failed with exit code ($dry.exit_code)"
    }
  }

  let paths = (
    $dry_output
    | lines
    | each { |line| $line | str trim }
    | where { |line| $line =~ '^/nix/store/[a-z0-9]{32}-' }
    | uniq
  )

  if ($paths | is-empty) {
    print "No missing substitutable store paths were reported by nix build --dry-run."
    return
  }

  print $"Querying binary-cache metadata for ($paths | length) paths ..."

  mut infos = []
  mut skipped_paths = 0
  for chunk in ($paths | chunks 200) {
    let query = (do { nix path-info --json --store $cache ...$chunk } | complete)

    if $query.exit_code != 0 {
      print $query.stderr
      error make {
        msg: $"nix path-info failed with exit code ($query.exit_code)"
      }
    }

    let stdout = ($query.stdout | str trim)

    if ($stdout | is-empty) {
      $skipped_paths = ($skipped_paths + ($chunk | length))
      continue
    }

    let parsed = ($stdout | from json)
    let batch_infos = (
      if (($parsed | describe) =~ "^record") {
        $parsed
        | transpose path info
        | each { |row|
          if ($row.info == null) {
            { path: $row.path narSize: 0 closureSize: 0 }
          } else {
            $row.info | upsert path $row.path
          }
        }
      } else {
        $parsed
      }
    )

    $infos = ($infos | append $batch_infos)
  }

  print $"Querying compressed download sizes with ($threads) parallel requests ..."

  let rows = (
    $infos
    | par-each --threads $threads { |info|
      let copied_bytes = ($info.narSize? | default 0)
      let download_bytes = (narinfo_filesize $cache $info.path)

      {
        download_mib: (mib $download_bytes)
        copied_mib: (mib $copied_bytes)
        name: (store_name $info.path)
        path: $info.path
        download_bytes: $download_bytes
        copied_bytes: $copied_bytes
      }
    }
    | sort-by --reverse download_bytes
  )

  let total_download = ($rows | get download_bytes | math sum)
  let total_copied = ($rows | get copied_bytes | math sum)

  print ""
  print $"Total planned compressed download: (mib $total_download) MiB"
  print $"Total planned copied/unpacked NAR size: (mib $total_copied) MiB"
  if $skipped_paths > 0 {
    print $"Paths without returned substituter metadata: ($skipped_paths)"
  }
  print $"Top ($top) grouped names by download size:"
  print ""

  let grouped_rows = (
    $rows
    | group-by name
    | transpose name rows
    | each { |group|
      let download_bytes = ($group.rows | get download_bytes | math sum)
      let copied_bytes = ($group.rows | get copied_bytes | math sum)
      {
        download_mib: (mib $download_bytes)
        copied_mib: (mib $copied_bytes)
        count: ($group.rows | length)
        name: $group.name
        download_bytes: $download_bytes
      }
    }
    | sort-by --reverse download_bytes
    | first $top
    | reject download_bytes
  )

  print ($grouped_rows | table)

  print ""
  print $"Top ($top) paths by download size:"
  print ""

  let top_path_rows = (
    $rows
    | first $top
    | select download_mib copied_mib name path
  )

  print ($top_path_rows | table)

  if $why {
    print ""
    print $"Dependency chains for top ($top) paths:"

    for row in $top_path_rows {
      print_why_depends $installable $row
    }
  }
}
