# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

nix-devshells is a Nix flake library that provides composable dev shell helpers. Consumers add it as a flake input and compose features via `mkDevShell`.

## Commands

There is no test suite or CI. Validate changes by evaluating the flake and entering shells:

```sh
nix flake check                          # evaluate flake outputs (catches eval errors)
nix develop                              # enter the repo's own dev shell
nix flake init --template ./#full        # scaffold from a template into an empty dir
nix-shell -p alejandra --run 'alejandra .'   # format all Nix files
```

To exercise a helper end-to-end, scaffold or open one of the `examples/` projects and run `nix develop` there; service helpers (Postgres/Redis) then expose `pg_start`/`redis_start` etc. on `$PATH`.

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

All helpers store dependencies under `$FLAKE_ROOT` in dotfile directories (`.gems/`, `.venv/`, `.npm-global/`, `.cargo/`, `.perl5/`). Exceptions: Postgres uses `$PWD/.postgres/` for data and `/tmp/nix-pg-<hash>` for sockets (to avoid macOS 103-byte Unix socket path limit). Redis uses `$PWD/.redis/` for per-project data/socket isolation.

### Helper structure

Every helper sets `${LANG}_APP_ROOT="$FLAKE_ROOT"`, configures paths, and prepends bins to `$PATH`. Ruby additionally unsets system gem variables for full isolation.

### Service helpers (Postgres, Redis)

Service shellHooks generate small wrapper scripts at runtime into `$PWD/.<service>/bin/` and prepend that dir to `$PATH`, giving the user lifecycle commands: `pg_start`/`pg_stop`/`pg_status` and `redis_start`/`redis_stop`/`redis_status`. Scripts are written with `cat > … <<'SCRIPT'` (quoted heredoc, so `$VAR` stays literal and resolves at call time). The service is **not** auto-started on shell entry — only initialized. Postgres creates a default database named after `$USER`; Redis listens on a Unix socket only and exports `REDIS_URL`. Postgres `shellHook` also migrates pre-existing configs to the new `/tmp` socket path via `sed`.

### Rust specifics

`withRust` also accepts `cargoPackage` (separate cargo override) and re-exports `rust`/`cargo` attributes for consumers. It bundles `clippy`, `rustfmt`, `pkg-config`, and `openssl_3` alongside the toolchain.

## Adding a new helper

1. Create `lib/<name>.nix` following the pattern: `{ pkgs, <version>? <default> }: { packages, shellHook, ... }`
2. Register it in `flake.nix` lib: `with<Name> = args: import ./lib/<name>.nix args;`
3. Use `$FLAKE_ROOT` (set by mkDevShell) for dependency storage paths
4. Add an example in the README

## Formatting

Nix files are formatted with alejandra. Run: `nix-shell -p alejandra --run 'alejandra .'`
