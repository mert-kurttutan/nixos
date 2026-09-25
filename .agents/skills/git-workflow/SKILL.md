---
name: git-workflow
description: Apply a secure, robust Git workflow for verified remote synchronization, safe commits, and controlled pushes.
---

# Git workflow

- Prefer the configured SSH remote unless another transport is explicitly requested.
- Verify SSH using the default Git/OpenSSH configuration; do not change environment variables, override SSH options, bypass host-key checks, or use alternate configs.
- Before SSH-based Git operations, check the Proton Pass SSH-agent daemon with `pass-cli ssh-agent daemon status` outside the sandbox. The sandbox hides the host daemon PID and can falsely report a stale socket. If the host check shows it is not running, start it with `pass-cli ssh-agent daemon start` outside the sandbox and use the configured Proton Pass socket.
