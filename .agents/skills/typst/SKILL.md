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

When asked to reproduce a PDF, first create a sibling working directory named after the source PDF with `.pdf` replaced by `.typst` (for example, `paper.pdf` → `paper.typst/`). Its function is to hold the document profile, Typst source files, generated PDFs, and trial artifacts. Then work in four phases:

1. **Extract source data.** If HTML and JSON are absent, run `pdf-process html <source.pdf> --json` to obtain HTML (including MathJax where available) and block-level JSON. Follow the [pdf-process CLI skill](../pdf-process-cli/SKILL.md) for authentication and execution.
2. **Identify the document type and structure.** Render the first 10 and last 3 PDF pages as images, without duplicating pages in short documents. Inspect those images and the extracted data to identify the type and style, such as an arXiv preprint, journal article, or slide deck. Choose a matching Typst Universe template when available; a Physical Review article may use [revtyp](https://typst.app/universe/package/revtyp/). Otherwise, use native Typst structure. Before writing Typst, save `document-profile.json` in the `.typst/` directory with the type, venue if known, classification evidence, and chosen structure or template. Record uncertainty rather than guessing.
3. **Draft the content and structure.** Use the extracted files and document profile to recover text, equations, and document order. Compile the Typst draft and refine it until the content and structure are close to the source.
4. **Refine the visual details.** Adjust fonts, sizes, spacing, and page layout. Compare the generated PDF with the source PDF, using visual inspection and programmatic analysis where useful. If Python dependencies are needed for comparison, run them with `uv run --with`. Aim for a convincing visual match; minor differences are acceptable unless the user requests stricter fidelity.

For phase 2, this command saves page images under `paper.typst/source-pages/` (replace the two paths):

```sh
uv run --no-project --with pymupdf python -c '
import sys
from pathlib import Path
import pymupdf

out = Path(sys.argv[2]) / "source-pages"
out.mkdir(parents=True, exist_ok=True)
with pymupdf.open(sys.argv[1]) as pdf:
    pages = sorted(set(range(min(10, len(pdf)))) | set(range(max(0, len(pdf) - 3), len(pdf))))
    for index in pages:
        pdf[index].get_pixmap(dpi=120).save(out / f"page-{index + 1:03}.png")
' paper.pdf paper.typst
```
