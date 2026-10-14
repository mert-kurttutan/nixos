---
name: python-dev
description: Develop, maintain, and troubleshoot Python projects using the repository's conventions.
---

# Python development

- Use `uv` for Python environments, dependencies, and commands unless the user or project specifies otherwise.
- For new packages, use the `src/` layout. Follow the existing layout in established projects.
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
