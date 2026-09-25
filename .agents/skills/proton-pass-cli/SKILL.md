---
name: proton-pass-cli
description: Use Proton Pass CLI for vaults, secrets, and its SSH-agent daemon.
---

# Proton Pass CLI

Start and stop the SSH-agent daemon first:

```sh
pass-cli ssh-agent daemon start
pass-cli ssh-agent daemon stop
```

Check status with `pass-cli ssh-agent daemon status` outside the sandbox; the sandbox hides the host daemon PID and can falsely report a stale socket. Set the socket for SSH:

```sh
export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
```

Install and authenticate:

```sh
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
pass-cli login
pass-cli info
```

Common operations:

```sh
pass-cli vault list
pass-cli item list --vault-name "Vault"
pass-cli item view "pass://Vault/Item/field"
pass-cli run -- command
```

Use scoped personal-access tokens for automation. Never print, commit, or log
token or secret values; use `pass-cli run` or `pass-cli inject` when possible.

Reference: https://protonpass.github.io/pass-cli/
