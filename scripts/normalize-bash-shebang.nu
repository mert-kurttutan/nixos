#!/usr/bin/env nu

def main [
    --check      # Report files that would change, but do not modify them.
] {
    let target_shebang = "#!/usr/bin/env bash"
    let old_shebangs = ["#!/bin/bash", "#!/usr/bin/bash"]
    let old_shebang_regex = '^#!(/usr/)?bin/bash\r?$'
    let search = (
        ^rg --files-with-matches --no-messages --regexp $old_shebang_regex
        | complete
    )
    let files = if $search.exit_code == 0 {
        $search.stdout | lines
    } else {
        []
    }

    mut changed = []

    for path in $files {
        if not ($path | path exists) {
            continue
        }

        let contents = try {
            open --raw $path | decode utf-8
        } catch {
            continue
        }
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
