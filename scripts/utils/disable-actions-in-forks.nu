#!/usr/bin/env nu

def action_setting [] {
  let permissions = $in
  let enabled = ($permissions.enabled? | default null)
  let allowed = ($permissions.allowed_actions? | default "unknown")
  let sha_pinning = ($permissions.sha_pinning_required? | default null)

  {
    enabled: $enabled
    allowed_actions: $allowed
    sha_pinning_required: $sha_pinning
  }
}

def print_progress_summary [
  repo: string
  status: string
  setting: record
  counts: record
] {
  print $"($repo): ($status)"
  print $"  actions: enabled=($setting.enabled) allowed_actions=($setting.allowed_actions) sha_pinning_required=($setting.sha_pinning_required)"
  print $"  summary: processed=($counts.processed)/($counts.total) disabled=($counts.disabled) already_disabled=($counts.already_disabled) skipped=($counts.skipped) failed=($counts.failed)"
}

def main [
  --owner: string # GitHub user or organization to scan. Defaults to the authenticated user.
  --limit: int = 1000 # Maximum repositories to request from gh.
  --include-archived # Include archived fork repositories.
  --dry-run # Show what would change without disabling Actions.
] {
  let resolved_owner = if ($owner | is-empty) {
    let user = (^gh api user --jq '.login' | complete)

    if $user.exit_code != 0 {
      print ($user.stderr | str trim)
      error make {
        msg: $"failed to read authenticated GitHub user with gh api: exit code ($user.exit_code)"
      }
    }

    $user.stdout | str trim
  } else {
    $owner
  }

  let repos_response = (
    ^gh repo list $resolved_owner --fork --limit $limit --json nameWithOwner,isArchived
    | complete
  )

  if $repos_response.exit_code != 0 {
    print ($repos_response.stderr | str trim)
    error make {
      msg: $"failed to list fork repositories for ($resolved_owner): exit code ($repos_response.exit_code)"
    }
  }

  let repos = (
    $repos_response.stdout
    | from json
    | where { |repo| $include_archived or not $repo.isArchived }
    | sort-by nameWithOwner
  )

  let skipped_archived = if $include_archived {
    0
  } else {
    (
      $repos_response.stdout
      | from json
      | where isArchived
      | length
    )
  }

  if ($repos | is-empty) {
    print $"No fork repositories found for ($resolved_owner)."
    if $skipped_archived > 0 {
      print $"Skipped archived forks: ($skipped_archived)"
    }
    return
  }

  print $"Found ($repos | length) fork repositories for ($resolved_owner)."
  if $dry_run {
    print "Dry run: no GitHub Actions settings will be changed."
  }
  if $skipped_archived > 0 {
    print $"Skipping ($skipped_archived) archived forks. Use --include-archived to include them."
  }
  print ""

  mut counts = {
    total: ($repos | length)
    processed: 0
    disabled: 0
    already_disabled: 0
    skipped: $skipped_archived
    failed: 0
  }

  for repo in $repos {
    let name = $repo.nameWithOwner
    $counts.processed = ($counts.processed + 1)

    let before_response = (^gh api $"repos/($name)/actions/permissions" | complete)

    if $before_response.exit_code != 0 {
      $counts.failed = ($counts.failed + 1)
      let setting = {
        enabled: "unknown"
        allowed_actions: "unknown"
        sha_pinning_required: "unknown"
      }

      print_progress_summary $name "failed to read Actions permissions" $setting $counts
      print $"  error: ($before_response.stderr | str trim)"
      print ""
      continue
    }

    let before = ($before_response.stdout | from json | action_setting)

    if $before.enabled == false {
      $counts.already_disabled = ($counts.already_disabled + 1)
      print_progress_summary $name "already disabled" $before $counts
      print ""
      continue
    }

    if $dry_run {
      print_progress_summary $name "would disable" $before $counts
      print ""
      continue
    }

    let update_response = (
      ^gh api --method PUT $"repos/($name)/actions/permissions" -F "enabled=false"
      | complete
    )

    if $update_response.exit_code != 0 {
      $counts.failed = ($counts.failed + 1)
      print_progress_summary $name "failed to disable" $before $counts
      print $"  error: ($update_response.stderr | str trim)"
      print ""
      continue
    }

    let after_response = (^gh api $"repos/($name)/actions/permissions" | complete)

    if $after_response.exit_code != 0 {
      $counts.failed = ($counts.failed + 1)
      print_progress_summary $name "disabled, but failed to verify final setting" $before $counts
      print $"  error: ($after_response.stderr | str trim)"
      print ""
      continue
    }

    let after = ($after_response.stdout | from json | action_setting)

    if $after.enabled == false {
      $counts.disabled = ($counts.disabled + 1)
      print_progress_summary $name "disabled" $after $counts
    } else {
      $counts.failed = ($counts.failed + 1)
      print_progress_summary $name "update did not disable Actions" $after $counts
    }

    print ""
  }

  print "Final summary:"
  print ($counts | table)

  if $counts.failed > 0 {
    exit 1
  }
}
