{
  description = "Reusable development environment helpers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-ruby,
    ...
  }: {
    lib = {
      withArduino = args: import ./lib/arduino.nix args;
      withNode = args: import ./lib/node.nix args;
      withPerl = args: import ./lib/perl.nix args;
      withPostgres = args: import ./lib/postgres.nix args;
      withPython = args: import ./lib/python.nix args;
      withRuby = args: import ./lib/ruby.nix args;
      withRedis = args: import ./lib/redis.nix args;
      withRust = args: import ./lib/rust.nix args;
      withSwift = args: import ./lib/swift.nix args;

      mkDevShell = {
        pkgs,
        features,
        extraPackages ? [],
        extraLibraries ? [],
        extraShellHook ? "",
      }:
        pkgs.mkShell {
          buildInputs = (builtins.concatLists (map (f: f.packages or []) features)) ++ extraPackages ++ extraLibraries;

          shellHook =
            ''
              # Find flake root by walking up until we find flake.nix
              _find_flake_root() {
                local dir="$PWD"
                while [ "$dir" != "/" ]; do
                  if [ -f "$dir/flake.nix" ]; then
                    echo "$dir"
                    return
                  fi
                  dir="$(dirname "$dir")"
                done
                echo "$PWD"
              }
              export FLAKE_ROOT="$(_find_flake_root)"
            ''
            + pkgs.lib.optionalString (extraLibraries != []) ''
              # FFI bindings (ruby-vips, pyvips, ...) dlopen libs by bare name and
              # never search the Nix store. FFI consults LD_LIBRARY_PATH on macOS
              # too (DYLD_* is stripped by SIP), so point it at each library dir.
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath extraLibraries}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            ''
            + (builtins.concatStringsSep "\n" (map (f: f.shellHook or "") features))
            + "\n"
            + extraShellHook;
        };
    };

    overlays.default = nixpkgs-ruby.overlays.default;

    # Each check writes the drvPath of a one-helper shell to a file. Getting
    # the drvPath evaluates every package in the shell without building any,
    # whereas `nix flake check` only looks at the top of a devShells output.
    checks = nixpkgs.lib.genAttrs ["aarch64-darwin" "aarch64-linux" "x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
      evalShell = name: feature:
        pkgs.writeText "${name}-shell-drv" (builtins.unsafeDiscardStringContext
          (self.lib.mkDevShell {
            inherit pkgs;
            features = [feature];
          })
          .drvPath);
    in
      builtins.mapAttrs evalShell {
        arduino = self.lib.withArduino {inherit pkgs;};
        node = self.lib.withNode {inherit pkgs;};
        perl = self.lib.withPerl {inherit pkgs;};
        postgres = self.lib.withPostgres {inherit pkgs;};
        python = self.lib.withPython {inherit pkgs;};
        redis = self.lib.withRedis {inherit pkgs;};
        ruby = self.lib.withRuby {inherit pkgs;};
        rust = self.lib.withRust {inherit pkgs;};
        swift = self.lib.withSwift {inherit pkgs;};
      });

    templates = rec {
      full = {
        path = ./templates/full;
        description = "Full-stack dev shell: Ruby, Python, Node, Postgres";
      };
      node = {
        path = ./templates/node;
        description = "Node.js dev shell";
      };
      python = {
        path = ./templates/python;
        description = "Python dev shell";
      };
      ruby = {
        path = ./templates/ruby;
        description = "Ruby dev shell";
      };
      rust = {
        path = ./templates/rust;
        description = "Rust dev shell";
      };
      swift = {
        path = ./templates/swift;
        description = "Swift dev shell with macOS GUI (SwiftUI/AppKit) support";
      };
      default = full;
    };
  };
}
