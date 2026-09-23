---
name: typst
description: Create or edit Typst documents and templates using native Typst features and package APIs.
---

# Typst

Use idiomatic Typst for document structure, layout, styling, and reusable behavior. Prefer native constructs and a package's supported configuration or public API.

Unless the user explicitly asks for one of these approaches:

- Do not use LaTeX hacks or insert LaTeX-generated content to reproduce a result.
- Do not place text at absolute coordinates to imitate document flow, layout, or package behavior.
- Do not copy or fork a Typst package merely to change its behavior. Configure or extend it through its public interface instead; if that is insufficient, explain the limitation and work within Typst's supported mechanisms.

## Replicating a PDF in Typst

When asked to reproduce a PDF, build the document in two passes:

1. Draft the content and structure first. Use `pdf-process html <source.pdf> --json` to extract HTML (including MathJax content where available) and block-level JSON when these files do not already exist. Follow the [pdf-process CLI skill](../pdf-process-cli/SKILL.md) for authentication and execution. Use the extracted files to recover text, equations, and document order. Compile the Typst draft and refine it until the content and structure are close to the source.
2. Refine the visual details, such as fonts, sizes, spacing, and page layout. Compare the generated PDF with the source PDF, using visual inspection and programmatic analysis where useful. If Python dependencies are needed for comparison, run them with `uv run --with`. Aim for a convincing visual match; minor differences are acceptable unless the user requests stricter fidelity.

Keep Typst source files, generated PDFs, and trial artifacts together in a sibling directory named after the source PDF with `.pdf` replaced by `.typst` (for example, `paper.pdf` → `paper.typst/`).
