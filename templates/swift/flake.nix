{
  description = "Swift dev shell with macOS GUI (SwiftUI/AppKit) support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-devshells.url = "github:gbp/nix-devshells";
  };

  outputs = {
    self,
    nixpkgs,
    nix-devshells,
  }: let
    # GUI support links the macOS SDK, so this template targets darwin only.
    systems = ["aarch64-darwin" "x86_64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = nix-devshells.lib.mkDevShell {
        inherit pkgs;
        features = [
          (nix-devshells.lib.withSwift {
            inherit pkgs;
            gui = true;
          })
        ];
      };
    });
  };
}
