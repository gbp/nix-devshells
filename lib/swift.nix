# Swift development environment helper
{
  pkgs,
  version ? "latest",
  package ? null,
  gui ? false,
}: let
  # nixpkgs ships a single Swift toolchain (no per-version attrs like nodejs_22),
  # so "latest" maps to pkgs.swift; use `package` to pin a custom derivation.
  swiftPackage =
    if package != null
    then package
    else pkgs.swift;
in {
  packages =
    [
      swiftPackage
      pkgs.swiftpm
      pkgs.swiftformat
      pkgs.swiftlint
    ]
    # GUI (AppKit/SwiftUI) apps link against the macOS SDK frameworks. This is
    # darwin-only; evaluating with gui = true on Linux will fail, by design.
    ++ pkgs.lib.optional gui pkgs.apple-sdk_15;

  shellHook =
    ''
      # Swift environment. SwiftPM keeps build output project-local in .build/,
      # so there is no global install dir to redirect like Ruby (.gems) or Node.
      export SWIFT_APP_ROOT="$FLAKE_ROOT"
    ''
    + pkgs.lib.optionalString gui ''
      # The nixpkgs Swift toolchain omits `dsymutil`, which SwiftPM invokes to
      # build debug symbols, so a plain `swift build` aborts partway through.
      # Disable debug-symbol generation to work around it.
      echo "[swift] GUI mode (apple-sdk_15). Build SwiftUI/AppKit apps with:"
      echo "        swift build -Xswiftc -gnone"
    '';

  # Expose for consumers
  swift = swiftPackage;
}
