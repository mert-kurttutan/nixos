# Oxlint baseline

Use this as a modest starting point for a new or lightly configured JS/TS project. Adapt it to the project's framework, test tools, generated files, and existing rules. Oxlint's built-in correctness rules are enabled by default; this config makes the baseline explicit and adds suspicious-pattern warnings without enabling every opinionated category.

```jsonc
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "categories": {
    "correctness": "error",
    "suspicious": "warn"
  }
}
```

Keep the default plugin set unless there is a reason to change it. Setting `plugins` replaces that set, so include every desired plugin when specifying it. Enable framework and test plugins deliberately (for example, `react`, `vitest`, or `jest`) and check the [built-in plugin list](https://oxc.rs/docs/guide/usage/linter/plugins.html) for current support.

Always expose Oxlint through `package.json` scripts and run those scripts with the repository's package manager. Do not call the `oxlint` executable directly unless the user explicitly asks for direct CLI use.

```json
{
  "scripts": {
    "lint": "oxlint",
    "lint:fix": "oxlint --fix"
  }
}
```

Run `npm run lint` or `pnpm run lint` to lint, and `npm run lint:fix` or `pnpm run lint:fix` to apply safe fixes. Inspect the resulting diff. Suggestion and dangerous-fix modes can change behavior; use them selectively and review every change.

## Optional TypeScript type-aware rules

Type-aware rules catch issues that need TypeScript's type information, such as floating promises. They add setup and checking cost, so enable them when the repository's TypeScript version and configuration are compatible, rather than turning them on by default.

Install `oxlint-tsgolint`, enable `options.typeAware` in the root config, and choose specific rules, for example:

```jsonc
{
  "options": {
    "typeAware": true
  },
  "rules": {
    "typescript/no-floating-promises": "error"
  }
}
```

The current Oxlint docs require TypeScript 7+ for type-aware linting and note unsupported legacy `tsconfig` options. `--type-check` is experimental; use the project's normal type checker unless deliberately adopting Oxlint's type-checking mode and validating compatibility.

## Rule selection

- Keep correctness findings as errors and consider suspicious findings as warnings initially; resolve or narrowly configure them as the project adopts the rules.
- Add rules individually when they address a real project need. Avoid enabling all `pedantic`, `style`, `restriction`, or `nursery` rules as a blanket policy.
- Do not assume Oxlint covers every ESLint plugin or framework template. Its support changes; check the current [rule list](https://oxc.rs/docs/guide/usage/linter/rules.html) and [compatibility notes](https://oxc.rs/compatibility.html).
- Oxlint does not format code. Pair it with the formatter selected by the project, such as Prettier or Oxfmt, and keep formatting separate from lint rules.

## Useful commands

For occasional maintenance commands such as initializing config or printing the effective config, add a named `package.json` script and invoke it with `npm run <script>` or `pnpm run <script>`. This environment uses Node.js with npm or pnpm; do not introduce Bun or Yarn commands. See the official [quickstart](https://oxc.rs/docs/guide/usage/linter/quickstart.html), [configuration guide](https://oxc.rs/docs/guide/usage/linter/config.html), and [type-aware linting guide](https://oxc.rs/docs/guide/usage/linter/type-aware.html) for current details.
