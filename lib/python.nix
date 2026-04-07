# Python development environment helper
{
  pkgs,
  version ? "3.13",
  package ? null,
}: let
  versionParts = builtins.splitVersion version;
  major = builtins.elemAt versionParts 0;
  minor = builtins.elemAt versionParts 1;
  pythonPackage =
    if package != null
    then package
    else pkgs."python${major}${minor}";
in {
  packages = [
    pythonPackage
    pkgs.gcc
    pkgs.libffi
    pkgs.openssl_3
    pkgs.pkg-config
    pkgs.zlib
  ];

  shellHook = ''
    # Python environment - uses $FLAKE_ROOT for shared venv
    export PYTHON_APP_ROOT="$FLAKE_ROOT"
    export VENV_DIR="$PYTHON_APP_ROOT/.venv"

    # Create venv if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
      ${pythonPackage}/bin/python -m venv "$VENV_DIR"
    fi

    # Activate venv
    source "$VENV_DIR/bin/activate"

    # Ensure pip is up to date
    export PIP_REQUIRE_VIRTUALENV=true

    # Build environment for native extensions
    export PKG_CONFIG_PATH="${pkgs.openssl_3.dev}/lib/pkgconfig:${pkgs.libffi.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export LD_LIBRARY_PATH="${pkgs.openssl_3}/lib:${pkgs.libffi}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  # Expose for consumers
  python = pythonPackage;
}
