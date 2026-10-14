---
name: python
description: Develop, maintain, and troubleshoot Python projects using the repository's conventions.
---

# Python development

- Use `uv` for Python environments, dependencies, and commands unless the user or project specifies otherwise.
- For a new app, start with `uv init <project-name>`; for a library, use `uv init --lib <project-name>`. Keep package code in the generated `src/` layout.
- Add runtime dependencies with `uv add <package>` and development tools with `uv add --dev <package>`. These commands update project metadata, the lockfile, and environment; use `uv run <command>` to run commands in the project environment.
- Follow the tools, versions, and commands configured in `pyproject.toml`, hook configuration, and CI. Use the project's test runner (often `uv run pytest`).
- When setting up Ruff, use [the Ruff TOML baseline](references/ruff.toml) as a starting point and adapt it to the project's layout and Python version. Existing project configuration and hooks take precedence; preserve narrow ignores and per-file exceptions, and review automatic fixes. Honor project-level Pylint settings when configured.
- For Git hooks, use [the pre-commit/prek YAML baseline](references/pre-commit-config.yaml) as a starting point. Keep one `.pre-commit-config.yaml`; `prek` supports this format directly. Follow the project's chosen runner, for example `uv run prek install` or `uv run pre-commit install`, and run its configured hooks through `uv run`.
- For standalone scripts and minimal reproducible examples, put dependencies in the script's PEP 723 inline metadata and use the `#!/usr/bin/env -S uv run --script` shebang. Make the script executable and show how to run it from its directory with `./<script.py>`. Inline metadata dependencies are used independently of project dependencies.

  ```python
  #!/usr/bin/env -S uv run --script
  #
  # /// script
  # dependencies = ["requests<3", "rich"]
  # ///

  import requests
  from rich.pretty import pprint

  response = requests.get("https://peps.python.org/api/peps.json")
  pprint(list(response.json().items())[:10])
  ```
