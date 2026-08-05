# Ruby development environment helper
{
  pkgs,
  version ? "4.0",
  package ? null,
}: let
  rubyPackage =
    if package != null
    then package
    else pkgs."ruby-${version}";

  # The gem ABI directory ("4.0.0" for any 4.0.x). Read it off the derivation
  # rather than the `version` string so it tracks nixpkgs Ruby bumps on its own:
  # ruby.libPath is "lib/ruby/4.0.0", so the basename is the ABI dir. Custom
  # `package` derivations may lack the passthru, so fall back to parsing.
  versionSplit = builtins.splitVersion version;
  rubyMajorMinor =
    if rubyPackage ? libPath
    then builtins.baseNameOf rubyPackage.libPath
    else if builtins.length versionSplit >= 2
    then "${builtins.elemAt versionSplit 0}.${builtins.elemAt versionSplit 1}.0"
    else throw "withRuby: cannot determine gem ABI directory from version ${version}; pass a `package` with a libPath passthru";
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

    # Set GEM paths to project-local only. GEM_HOME must be set, not just
    # BUNDLE_PATH: Bundler's generated bin/bundle binstub runs
    # `gem "bundler", <BUNDLED WITH>` before Bundler loads, so that lookup goes
    # through plain RubyGems, which only consults GEM_HOME/GEM_PATH. Without
    # this, a project pinned to an older bundler than the one Ruby ships as a
    # default gem fails to activate it even though it is installed under
    # BUNDLE_PATH.
    export GEM_HOME="$BUNDLE_PATH/ruby/${rubyMajorMinor}"
    export GEM_PATH="$GEM_HOME"
    export GEM_SPEC_CACHE="$BUNDLE_PATH/spec_cache"

    # Add project bins to PATH (both shared and project-specific)
    export PATH="$PWD/bin:$RUBY_APP_ROOT/bin:$GEM_HOME/bin:$PATH"

    # Build environment
    export PKG_CONFIG_PATH="${pkgs.curl.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export LD_LIBRARY_PATH="${pkgs.curl}/lib:${pkgs.openssl_3}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  # Expose for consumers that need it
  ruby = rubyPackage;
  inherit rubyMajorMinor;
}
