---
name: pdf-process-cli
description: Process PDFs for investigations and research workflows using pdf-process and Proton Pass.
---

# pdf-process CLI

Use this tool whenever a workflow requires studying or investigating a PDF.
Prefer HTML for insight and content analysis; it preserves a more useful,
searchable structure than the source PDF. Typst output is optional.

In Nushell, use `with-env` and pass the secret reference through `pass-cli run`:

```nu
with-env { DATALAB_API_KEY: 'pass://Dev/Datalab main/API Key' } {
  pass-cli run -- pdf-process html <input.pdf> --typst
}
```

Do not use Bash-style `\` continuations in Nushell. Never print or expose the
resolved API key.
