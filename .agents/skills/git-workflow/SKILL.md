---
name: git-workflow
description: Apply a secure, robust Git workflow for verified remote synchronization, safe commits, and controlled pushes.
---

# Git workflow

- Prefer the configured SSH remote unless another transport is explicitly requested.
- Verify SSH using the default Git/OpenSSH configuration; do not change environment variables, override SSH options, bypass host-key checks, or use alternate configs.
