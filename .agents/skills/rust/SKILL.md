---
name: rust
description: Develop, maintain, and troubleshoot Rust projects using the project's Cargo and toolchain conventions.
---

# Rust development

- Follow the project's `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml` (or legacy `rust-toolchain`), Nix dev shell, and CI configuration. Preserve the selected edition, minimum supported Rust version, and toolchain; do not upgrade them as incidental cleanup.
- Use Cargo for Rust project workflows. For a new binary, start with `cargo new <project-name>`; for a library, use `cargo new <project-name> --lib`. Keep a committed `Cargo.lock` for applications and follow the library's existing lockfile policy.
- Add dependencies with `cargo add` when supported by the project's Cargo version; otherwise edit `Cargo.toml` and let Cargo update the lockfile. Avoid adding dependencies when the standard library or an existing dependency is sufficient.
- Use the toolchain selected by the project. This host provides `rustup`, `rustc`, and `cargo`; do not add another Rust installation or toolchain to a Nix dev shell without a project need. Respect project-specific tool wrappers and environment setup.
- Follow existing module, error-handling, and API conventions. Keep public APIs minimal and documented; avoid `unwrap`/`expect` in recoverable production paths, while using them when failure is intentionally impossible or in concise tests.
- Follow the project's lint configuration and CI checks. Common checks are `cargo fmt --check` and `cargo clippy --all-targets --all-features`; use the project's documented feature and target selections when they differ. Run Clippy from the same toolchain used to compile the project.
- Treat Rustfmt's line width as a configurable team style, not a universal hard cap. For projects that want Rustfmt to keep more calls, literals, and chains on one line, use the starter config in `references/rustfmt.toml`; it follows matklad's `use_small_heuristics = "Max"` preference and keeps module declaration order as written, without pinning the Rust edition. `use_small_heuristics` adjusts several width thresholds, including `chain_width`; it does not set `max_width`. Keep project-specific settings in the repository's own `rustfmt.toml` or `.rustfmt.toml`, and use the same config in editors and CI. Width is a formatting target, and heuristics or long strings/macros can still produce surprising layouts; inspect the result before adding explicit width overrides.
- Clippy's default lints (`clippy::all`) are a good baseline. Do not enable the full `pedantic`, `nursery`, or `restriction` groups by default; opt into specific extra lints only when they fit the project. Do not add `-D warnings` unless the project already enforces it or the user asks; when suppressing a useful lint, keep the allow narrow and explain intentional exceptions.
- For binaries, verify relevant CLI behavior and error paths. For libraries, cover public behavior and edge cases with unit or integration tests, and update documentation or examples when public APIs change.
