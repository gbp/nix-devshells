{
  description = "Example: PostgreSQL 13 from an older nixpkgs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-pg13.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-devshells.url = "github:gbp/nix-devshells";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-pg13,
    nix-devshells,
  }: let
    systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      pkgs-pg13 = import nixpkgs-pg13 {inherit system;};
    in {
      default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        features = [
          (nix-devshells.lib.withPostgres {
            inherit pkgs;
            package = pkgs-pg13.postgresql_13;
          })
          (nix-devshells.lib.withRedis {inherit pkgs;})
        ];
      };
    });
  };
}
