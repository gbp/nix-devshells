# nix-devshells

Modular, composable Nix flake helpers for development environments. Pick the languages and services you need, and get a reproducible dev shell with sensible defaults.

## Quick start

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-devshells.url = "github:gbp/nix-devshells";
  };

  outputs = {
    self,
    nixpkgs,
    nix-devshells,
  }: let
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nix-devshells.overlays.default];
      };
    in {
      default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        features = [
          (nix-devshells.lib.withNode {inherit pkgs; version = "24";})
          (nix-devshells.lib.withPostgres {inherit pkgs;})
          (nix-devshells.lib.withRuby {inherit pkgs; version = "4.0";})
        ];
      };
    });
  };
}
```

Then enter the shell:

```sh
nix develop
```

## Available helpers

| Helper | Arg | Default | Example |
|---|---|---|---|
| `withNode` | `version` | `"24"` | `"22"`, `"20.1.0"` |
| `withPerl` | `version` | `"latest"` | `"latest"` |
| `withPostgres` | `version` | `"16"` | `"17"`, `"15.2"` |
| `withPython` | `version` | `"3.13"` | `"3.12"`, `"3.11.5"` |
| `withRuby` | `version` | `"4.0"` | `"4.0.2"`, `"3.3.0"` |
| `withRust` | `version` | `"latest"` | `"latest"` |

Versions are parsed automatically -- pass natural version strings like `"3.12.1"` and the correct nixpkgs package is resolved.

All helpers also accept an optional `package` argument to use a custom package directly (e.g. from an older nixpkgs). When `package` is set, `version` is ignored. Rust additionally accepts `cargoPackage`.

Ruby versions are provided by [nixpkgs-ruby](https://github.com/bobvanderlinden/nixpkgs-ruby) and support exact version pinning.

## How it works

`mkDevShell` combines features into a single `mkShell`. Each feature provides:
- `packages` -- build inputs for the shell
- `shellHook` -- shell setup that runs on entry

A `$FLAKE_ROOT` variable is set automatically, pointing to the directory containing your `flake.nix`. Language helpers use this to store dependencies at the project root:

| Helper | Install path |
|---|---|
| Node | `$FLAKE_ROOT/.npm-global/` (global installs) |
| Perl | `$FLAKE_ROOT/.perl5/` |
| Postgres | `$PWD/.postgres/` |
| Python | `$FLAKE_ROOT/.venv/` |
| Ruby | `$FLAKE_ROOT/.gems/` |
| Rust | `$FLAKE_ROOT/.cargo/` |

## Extra packages and shell hooks

```nix
nix-devshells.lib.mkDevShell {
  inherit pkgs;
  features = [
    (nix-devshells.lib.withRuby {inherit pkgs;})
  ];
  extraPackages = [pkgs.jq];
  extraShellHook = ''
    echo "Ready to go!"
  '';
};
```

## Examples

- [`examples/custom-postgres/`](examples/custom-postgres/) -- PostgreSQL 13 from an older nixpkgs with Redis
- [`examples/full-stack/`](examples/full-stack/) -- Ruby, Python, Node, Postgres
- [`examples/monorepo/`](examples/monorepo/) -- shared shell with nested projects using `source_up` in direnv
- [`examples/ruby-only/`](examples/ruby-only/) -- just Ruby
