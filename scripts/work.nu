#!/usr/bin/env nu

# User-facing dispatcher for remote development and local VM workflows.
# Install it, together with the other executable scripts, with:
#   nu scripts/sync-local-bin.nu

use ./connect-github-codespace.nu [codespace-connect]
use ./setup-codespace.nu [codespace-setup]
use ./prepare-tt.nu [tt-prepare]
use ./deploy-koyeb-sshd.nu [koyeb-deploy]

def fail [message: string] {
  error make { msg: $message }
}

def require-command [name: string] {
  if (which $name | is-empty) {
    fail $"required command not found: ($name)"
  }
}

def show-help [] {
  print "work - shortcuts for development environments"
  print ""
  print "Codespaces:"
  print "  work codespace connect [owner/repository]"
  print "  work codespace setup"
  print ""
  print "Tenstorrent:"
  print "  work tt prepare"
  print "  work tt build"
  print ""
  print "Koyeb GPU server:"
  print "  work koyeb deploy"
  print ""
  print "Local libvirt VMs:"
  print "  work vm list"
  print "  work vm start <name>"
  print "  work vm stop <name>"
  print "  work vm console <name>"
}

def codespace [action: string, target?: string] {
  match $action {
    "connect" | "shell" => {
      if ($target | is-empty) {
        codespace-connect
      } else {
        codespace-connect $target
      }
    }
    "setup" => codespace-setup
    _ => (fail $"unknown Codespace action: ($action)")
  }
}

def tenstorrent [action: string] {
  match $action {
    "prepare" => tt-prepare
    "build" => {
      let project = ($env.HOME | path join "projects/tenstorrent/tt-metal")
      if not ($project | path exists) {
        fail $"Tenstorrent project not found: ($project); run 'work tt prepare' first"
      }
      require-command nix
      cd $project
      run-external nix ...["develop" "--command" "./build_metal.sh"]
    }
    _ => (fail $"unknown Tenstorrent action: ($action)")
  }
}

def koyeb [action: string] {
  match $action {
    "deploy" => koyeb-deploy
    _ => (fail $"unknown Koyeb action: ($action)")
  }
}

def vm [action: string, name?: string] {
  require-command virsh

  match $action {
    "list" => (run-external virsh ...["list" "--all"])
    "start" => {
      if ($name | is-empty) { fail "usage: work vm start <name>" }
      run-external virsh ...["start" $name]
    }
    "stop" => {
      if ($name | is-empty) { fail "usage: work vm stop <name>" }
      run-external virsh ...["shutdown" $name]
    }
    "console" => {
      if ($name | is-empty) { fail "usage: work vm console <name>" }
      run-external virsh ...["console" $name]
    }
    _ => (fail $"unknown VM action: ($action)")
  }
}

def main [
  area?: string
  action?: string
  target?: string
  --help(-h)
] {
  if $help or ($area | is-empty) {
    show-help
    return
  }

  let selected_action = $action | default ""

  match $area {
    "codespace" | "cs" => (codespace $selected_action $target)
    "tt" => (tenstorrent $selected_action)
    "koyeb" | "gpu" => (koyeb $selected_action)
    "vm" => (vm $selected_action $target)
    "help" => (show-help)
    _ => (fail $"unknown workflow: ($area); run 'work help'")
  }
}
