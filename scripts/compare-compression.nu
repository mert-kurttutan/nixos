#!/usr/bin/env nu

# Compare an archive downloaded from a URL with a zstd-compressed repack.
#
# The input must be a tar archive (for example .tar.gz, .tar.xz, or .tar.bz2).
# The archive is extracted before recompression; zstd is never applied directly
# to the original compressed stream.

def main [
  url: string
] {
  let work = (^mktemp --directory | str trim)

  let archive = ($work | path join "source-archive")
  let extracted = ($work | path join "extracted")
  let zstd_archive = ($work | path join "repacked.tar.zst")

  mkdir $extracted

  try {
    print $"Downloading ($url)"
    let download = (^curl --fail --location --show-error --silent --output $archive $url | complete)
    if $download.exit_code != 0 {
      error make { msg: $"download failed: ($download.stderr | str trim)" }
    }

    print "Extracting source archive"
    let extract = (^tar --extract --file $archive --directory $extracted | complete)
    if $extract.exit_code != 0 {
      error make {
        msg: "could not extract the URL as a tar archive"
        help: ($extract.stderr | str trim)
      }
    }

    print "Repacking with zstd -19"
    let repack = (
      ^tar
      --create
      --file -
      --directory $extracted
      --sort=name
      --owner=0
      --group=0
      --numeric-owner
      --mtime="UTC 1970-01-01"
      .
      | ^zstd --compress --ultra --threads=0 -19 --force -o $zstd_archive
      | complete
    )
    if $repack.exit_code != 0 {
      error make {
        msg: "zstd repack failed"
        help: ($repack | to nuon)
      }
    }

    let original_size = (ls -l $archive | get size | first | into int)
    let zstd_size = (ls -l $zstd_archive | get size | first | into int)
    let saved = $original_size - $zstd_size
    let change = (($zstd_size - $original_size) / ($original_size | into float)) * 100

    print ""
    print $"Original: ($original_size) bytes"
    print $"zstd:     ($zstd_size) bytes"
    print $"Difference: ($saved) bytes"
    print $"zstd size change: ($change)%"
  } finally {
    rm --recursive --force $work
  }
}
