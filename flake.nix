{
  description = "Reusable development environment helpers";

  inputs = {
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };

  outputs = {
    self,
    nixpkgs-ruby,
    ...
  }: {
    lib = {
      withNode = args: import ./lib/node.nix args;
      withPerl = args: import ./lib/perl.nix args;
      withPostgres = args: import ./lib/postgres.nix args;
      withPython = args: import ./lib/python.nix args;
      withRuby = args: import ./lib/ruby.nix args;
      withRedis = args: import ./lib/redis.nix args;
      withRust = args: import ./lib/rust.nix args;

      mkDevShell = {
        pkgs,
        features,
        extraPackages ? [],
        extraShellHook ? "",
      }:
        pkgs.mkShell {
          buildInputs = (builtins.concatLists (map (f: f.packages or []) features)) ++ extraPackages;

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
            + (builtins.concatStringsSep "\n" (map (f: f.shellHook or "") features))
            + "\n"
            + extraShellHook;
        };
    };

    overlays.default = nixpkgs-ruby.overlays.default;
  };
}
