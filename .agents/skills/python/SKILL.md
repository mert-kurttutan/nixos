---
name: python
description: Develop, maintain, and troubleshoot Python projects using the repository's conventions.
---

# Python development

- Use `uv` for Python environments, dependencies, and commands unless the user or project specifies otherwise.
- For a new app, start with `uv init <project-name>`; for a library, use `uv init --lib <project-name>`. Keep package code in the generated `src/` layout.
- Add runtime dependencies with `uv add <package>` and development tools with `uv add --dev <package>`. These commands update project metadata, the lockfile, and environment; use `uv run <command>` to run commands in the project environment.
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
