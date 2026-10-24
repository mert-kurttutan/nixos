---
name: js-ts
description: Develop, maintain, and troubleshoot JavaScript and TypeScript projects using their existing package manager, framework, and tooling conventions.
---

# JavaScript and TypeScript development

- Follow the repository's package manager, lockfile, Node version, scripts, framework, and CI. Do not switch package managers or upgrade the toolchain as incidental cleanup.
- Use Node.js with npm or pnpm for JavaScript tooling. Do not introduce Bun or Yarn commands or configuration.
- Use the existing project workflow for dependencies and commands. For a new project, use the framework's current official scaffold and select TypeScript only when the project needs it; do not add a framework to a standalone library or script without a reason.
- Treat type checking, linting, formatting, and building as separate jobs. In Vite projects, Vite transpiles TypeScript but does not type-check it; use the project's type checker (commonly `tsc --noEmit`) separately.
- For Oxlint, use the project's `package.json` scripts as the normal entry point; do not invoke `oxlint` directly unless the user explicitly asks for it. See [the starter config and rule guidance](references/oxlint.md). Preserve existing ESLint rules or plugins that Oxlint does not support; consult the compatibility docs before replacing an established configuration.
- For Oxfmt formatting, follow [the Oxfmt guidance](references/oxfmt.md). Keep the formatter already selected by a project unless a formatter migration is part of the task.
- Enable Oxlint's type-aware rules only when the project and installed versions support them. They require additional setup and currently have TypeScript compatibility constraints; retain the framework or TypeScript checker as appropriate.
- Use the framework's checker for component files. For Svelte, run `svelte-check`; Oxlint does not currently lint Svelte component templates.
- Review automated lint fixes, especially suggestions or dangerous fixes, before accepting behavior-changing edits. Keep suppressions narrow and explain non-obvious exceptions.
- Follow existing tests and build checks when changing behavior. Update relevant docs, examples, or lockfiles when project configuration or dependencies change.
