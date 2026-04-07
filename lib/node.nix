# Node.js development environment helper
{
  pkgs,
  version ? "24",
}: let
  major = builtins.head (builtins.splitVersion version);
  nodePackage = pkgs."nodejs_${major}";
in {
  packages = [nodePackage];

  shellHook = ''
    # Node.js environment - uses $FLAKE_ROOT for shared packages
    export NODE_APP_ROOT="$FLAKE_ROOT"
    export NPM_CONFIG_PREFIX="$NODE_APP_ROOT/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    mkdir -p "$NPM_CONFIG_PREFIX"
  '';

  # Expose for consumers
  node = nodePackage;
}
