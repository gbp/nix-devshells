{
  description = "iOS dev shell driving Xcode from the CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-devshells.url = "github:gbp/nix-devshells";
  };

  outputs = {
    self,
    nixpkgs,
    nix-devshells,
  }: let
    # xcodegen is packaged for Apple Silicon only.
    systems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        features = [
          (nix-devshells.lib.withIos {inherit pkgs;})
        ];
      };
    });
  };
}
