{
  description = "Node.js dev shell";

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
      pkgs = import nixpkgs {inherit system;};
    in {
      default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        features = [
          (nix-devshells.lib.withNode {inherit pkgs;})
        ];
      };
    });
  };
}
