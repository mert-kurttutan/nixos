#!/usr/bin/env nu

# Open an interactive SSH shell in a GitHub Codespace.
#
# Examples:
#   ./scripts/connect-github-codespace.nu owner/repository
#   ./scripts/connect-github-codespace.nu --codespace my-codespace
#   ./scripts/connect-github-codespace.nu --command 'uname -a' owner/repository
#   ./scripts/connect-github-codespace.nu --branch main owner/repository
# Nushell does not use a backslash for line continuation; run commands on one line.

def fail [message: string] {
  error make { msg: $message }
}

def require-command [name: string] {
  if (which $name | is-empty) {
    fail $"required command not found: ($name)"
  }
}

def command-error [result: record, command: string] {
  let details = ($result.stderr | str trim | default ($result.stdout | str trim))
  fail $"($command) failed: ($details)"
}

def current-repository [] {
  let result = (do { ^git remote get-url origin } | complete)

  if $result.exit_code != 0 {
    return null
  }

  $result.stdout
  | str trim
  | str replace --regex '^git@github\.com:' ''
  | str replace --regex '^https://github\.com/' ''
  | str replace --regex '\.git$' ''
}

def main [
  repository?: string
  --codespace(-c): string
  --branch(-b): string
  --repo-owner: string
  --profile: string
  --command(-e): string
] {
  require-command gh

  let repo = if ($repository | is-empty) {
    current-repository
  } else {
    $repository
  }

  if ($codespace | is-empty) and ($repo | is-empty) {
    fail "provide a repository, --codespace, or run from a GitHub repository"
  }

  let selected_codespace = if not ($codespace | is-empty) {
    $codespace
  } else {
    let listed = (do {
      ^gh codespace list --repo $repo --json name --jq '.[0].name'
    } | complete)

    if $listed.exit_code != 0 {
      command-error $listed "gh codespace list"
    }

    let existing = ($listed.stdout | str trim)
    if $existing != "" {
      $existing
    } else {
      print $"no Codespace found for ($repo); creating one"
      let create_args = if ($branch | is-empty) {
        ["codespace", "create", "--repo", $repo]
      } else {
        ["codespace", "create", "--repo", $repo, "--branch", $branch]
      }

      # Keep creation attached to the terminal so gh can prompt for a machine
      # type and any other interactive choices.
      ^gh ...$create_args

      let after_create = (do {
        ^gh codespace list --repo $repo --json name --jq '.[0].name'
      } | complete)
      if $after_create.exit_code != 0 {
        command-error $after_create "gh codespace list"
      }

      let created_name = ($after_create.stdout | str trim)
      if $created_name == "" {
        fail $"Codespace creation succeeded, but no Codespace was found for ($repo)"
      }

      $created_name
    }
  }

  mut args = ["codespace", "ssh", "--codespace", $selected_codespace]

  if not ($repo_owner | is-empty) {
    $args = ($args | append ["--repo-owner", $repo_owner])
  }

  if not ($profile | is-empty) {
    $args = ($args | append ["--profile", $profile])
  }

  if not ($command | is-empty) {
    $args = ($args | append ["--", $command])
  }

  let destination = if not ($codespace | is-empty) {
    $codespace
  } else {
    $repo
  }

  print $"connecting to GitHub Codespace ($destination)"
  run-external gh ...$args
}
