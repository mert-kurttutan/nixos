#!/usr/bin/env nu

def main [
    --check      # Report files that would change, but do not modify them.
] {
    let target_shebang = "#!/usr/bin/env bash"
    let old_shebangs = ["#!/bin/bash", "#!/usr/bin/bash"]
    let files = (glob --no-dir **/*.{sh,bash})

    mut changed = []

    for path in $files {
        let contents = open --raw $path
        let first_line = ($contents | lines | first)

        if $first_line in $old_shebangs {
            $changed = ($changed | append $path)

            if not $check {
                let updated = (
                    $contents
                    | str replace --regex '^#!\/(usr\/)?bin\/bash' $target_shebang
                )
                $updated | save --force $path
            }
        }
    }

    if ($changed | is-empty) {
        print "All bash shebangs are already portable."
        return
    }

    if $check {
        print "Files with non-portable bash shebangs:"
    } else {
        print "Updated bash shebangs:"
    }

    $changed | each {|path| print $"  ($path)" }

    if $check {
        exit 1
    }
}
