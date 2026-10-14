---
name: create-skill
description: Create or update Codex skills managed by this system configuration, then install them into Codex.
---

# Create a system skill

Use this skill when creating or updating a Codex skill that should be managed by
this system configuration.

Use the available `skill-creator` skill to design, write, and validate the
requested skill. This system repository is intended to live at `~/nixos`.
Store each managed skill in its own directory under
`~/nixos/.agents/skills/` (or `.agents/skills/` relative to the checkout), with
a `SKILL.md` entrypoint and only the supporting files its workflow needs. Do
not copy the generic `skill-creator` skill into this directory.

After creating or updating the requested skill, install the repository's
managed skills into Codex with the repo installer:

```bash
nu /home/kmert/nixos/scripts/utils/install-codex-skills.nu
```

The installer copies skills from this checkout's `.agents/skills/` directory
into the Codex skills directory. It uses `CODEX_HOME` when set, or
`~/.codex` otherwise.
