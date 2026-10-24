# Oxfmt formatting

Oxfmt is a formatter, separate from Oxlint. Follow the project's existing formatting tool and configuration; use Oxfmt when the project has adopted it or the task asks for it.

Install it as a development dependency with the project's package manager:

```sh
npm add -D oxfmt
# or
pnpm add -D oxfmt
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "format": "oxfmt",
    "format:check": "oxfmt --check"
  }
}
```

`npm run format` or `pnpm run format` formats files in place. Use `npm run format:check` or `pnpm run format:check` in CI to check without writing changes. Review the diff after formatting.

## Configuration and behavior

- Oxfmt works without a config. Generate a starter config with `npm exec oxfmt -- --init` or `pnpm exec oxfmt --init` when project-level settings are needed.
- Supported config files include `.oxfmtrc.json`, `.oxfmtrc.jsonc`, `oxfmt.config.ts`, and `oxfmt.config.mts`. Use `$schema: "./node_modules/oxfmt/configuration_schema.json"` for editor validation.
- Oxfmt's default `printWidth` is 100, while Prettier's default is 80. Set `printWidth` explicitly when matching an existing project's layout or during a Prettier migration.
- Oxfmt is Prettier-compatible for many configurations, but does not support arbitrary Prettier plugins. Some popular plugin features are built in; check the current compatibility matrix before migrating.
- If migrating from Prettier, `npm exec oxfmt -- --migrate prettier` or `pnpm exec oxfmt --migrate prettier` can convert supported configuration. Review migration warnings and the complete formatting diff.
- Oxfmt does not lint or type-check. Keep Oxlint and the project's TypeScript/framework checker as separate checks.

## Useful commands

```sh
oxfmt --check                 # check without writing
oxfmt --list-different        # list files needing changes
oxfmt --init                  # create starter config
oxfmt --migrate prettier      # migrate supported Prettier settings
```

Run local project dependencies through `npm exec` or `pnpm exec` as appropriate. Do not use Bun or Yarn.

## Official links

- [Oxfmt overview and quickstart](https://oxc.rs/docs/guide/usage/formatter/quickstart.html)
- [Configuration](https://oxc.rs/docs/guide/usage/formatter/config.html)
- [Prettier migration guide](https://oxc.rs/docs/guide/usage/formatter/migrate-from-prettier.html)
- [Oxlint and Oxfmt compatibility matrix](https://oxc.rs/compatibility.html)
- [Oxc playground, formatter mode](https://playground.oxc.rs/?t=formatter)
