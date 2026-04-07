# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

nix-devshells is a Nix flake library that provides composable dev shell helpers. Consumers add it as a flake input and compose features via `mkDevShell`.

## Architecture

`flake.nix` exposes `lib` with:
- `withRuby`, `withNode`, `withPython`, `withPostgres`, `withRedis`, `withRust`, `withPerl` — each imports its corresponding `lib/*.nix`
- `mkDevShell { pkgs, features, extraPackages?, extraShellHook? }` — merges all features into a single `pkgs.mkShell`. It defines `_find_flake_root` and exports `$FLAKE_ROOT` **before** any feature shellHooks run, so helpers can depend on it.

Each `lib/*.nix` is a function `{ pkgs, <versionArg> ? <default>, package ? null } -> { packages, shellHook, ... }`. The optional `package` argument overrides version resolution with a custom derivation. They are independent and composable in any combination.

## Conventions

### Version parsing

Versions are passed as human-readable strings and parsed to nixpkgs attribute names:
- **Ruby**: `"4.0.2"` → `pkgs."ruby-4.0.2"` (nixpkgs-ruby overlay, exact match)
- **Node**: `"22.1.0"` → `pkgs.nodejs_22` (major only via `builtins.head (builtins.splitVersion ...)`)
- **Python**: `"3.12"` → `pkgs.python312` (major+minor concatenated, no separator)
- **Postgres**: `"16.2"` → `pkgs.postgresql_16` (major only)
- **Redis**: `"latest"` uses `pkgs.redis`, otherwise version-specific attribute
- **Rust/Perl**: `"latest"` uses default package, otherwise version-specific attribute

### Dependency paths

All helpers store dependencies under `$FLAKE_ROOT` in dotfile directories (`.gems/`, `.venv/`, `.npm-global/`, `.cargo/`, `.perl5/`). Exceptions: Postgres uses `$PWD/.postgres/` and Redis uses `$PWD/.redis/` for per-project data/socket isolation.

### Helper structure

Every helper sets `${LANG}_APP_ROOT="$FLAKE_ROOT"`, configures paths, and prepends bins to `$PATH`. Ruby additionally unsets system gem variables for full isolation.

## Adding a new helper

1. Create `lib/<name>.nix` following the pattern: `{ pkgs, <version>? <default> }: { packages, shellHook, ... }`
2. Register it in `flake.nix` lib: `with<Name> = args: import ./lib/<name>.nix args;`
3. Use `$FLAKE_ROOT` (set by mkDevShell) for dependency storage paths
4. Add an example in the README

## Formatting

Nix files are formatted with alejandra. Run: `nix-shell -p alejandra --run 'alejandra .'`
