# Ruby development environment helper
{
  pkgs,
  version ? "4.0",
}: let
  rubyPackage = pkgs."ruby-${version}";
  versionSplit = builtins.splitVersion version;
  rubyMajorMinor = "${builtins.elemAt versionSplit 0}.${builtins.elemAt versionSplit 1}.0";
in {
  packages = [
    rubyPackage
    pkgs.curl
    pkgs.gcc
    pkgs.libxml2
    pkgs.libxslt
    pkgs.libyaml
    pkgs.openssl_3
    pkgs.pkg-config
    pkgs.zlib
  ];

  shellHook = ''
    # Ruby environment - uses $FLAKE_ROOT for shared gems
    export RUBY_APP_ROOT="$FLAKE_ROOT"

    # Complete Ruby environment isolation
    unset GEM_HOME
    unset GEM_PATH
    unset GEM_SPEC_CACHE
    unset RUBYOPT
    unset RUBYLIB

    # Bundle configuration - gems shared in flake root .gems
    export BUNDLE_PATH="$RUBY_APP_ROOT/.gems"
    export BUNDLE_APP_CONFIG="$RUBY_APP_ROOT/.bundle"

    # Set GEM paths to project-local only
    export GEM_PATH="$RUBY_APP_ROOT/.gems/ruby/${rubyMajorMinor}"
    export GEM_SPEC_CACHE="$RUBY_APP_ROOT/.gems/spec_cache"

    # Add project bins to PATH (both shared and project-specific)
    export PATH="$PWD/bin:$RUBY_APP_ROOT/bin:$RUBY_APP_ROOT/.gems/ruby/${rubyMajorMinor}/bin:$PATH"

    # Build environment
    export PKG_CONFIG_PATH="${pkgs.curl.dev}/lib/pkgconfig"
    export LD_LIBRARY_PATH="${pkgs.curl}/lib:${pkgs.openssl_3}/lib"
  '';

  # Expose for consumers that need it
  ruby = rubyPackage;
  inherit rubyMajorMinor;
}
