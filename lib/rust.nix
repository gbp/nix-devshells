# Rust development environment helper
{
  pkgs,
  version ? "latest",
  package ? null,
  cargoPackage ? null,
}: let
  rustPackage =
    if package != null
    then package
    else if version == "latest"
    then pkgs.rustc
    else pkgs."rust_${builtins.replaceStrings ["."] ["_"] version}";
  resolvedCargoPackage =
    if cargoPackage != null
    then cargoPackage
    else if version == "latest"
    then pkgs.cargo
    else pkgs."cargo_${builtins.replaceStrings ["."] ["_"] version}";
in {
  packages = [
    rustPackage
    resolvedCargoPackage
    pkgs.clippy
    pkgs.rustfmt
    pkgs.pkg-config
    pkgs.openssl_3
  ];

  shellHook = ''
    # Rust environment - uses $FLAKE_ROOT for shared cargo cache
    export RUST_APP_ROOT="$FLAKE_ROOT"
    export CARGO_HOME="$RUST_APP_ROOT/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    mkdir -p "$CARGO_HOME"
  '';

  # Expose for consumers
  rust = rustPackage;
  cargo = resolvedCargoPackage;
}
