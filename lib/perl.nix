# Perl development environment helper
{
  pkgs,
  version ? "latest",
}: let
  perlPackage =
    if version == "latest"
    then pkgs.perl
    else pkgs."perl${builtins.replaceStrings ["."] [""] version}";
in {
  packages = [
    perlPackage
    pkgs.perlPackages.locallib
  ];

  shellHook = ''
    # Perl environment - uses $FLAKE_ROOT for shared local::lib
    export PERL_APP_ROOT="$FLAKE_ROOT"
    export PERL5LIB="$PERL_APP_ROOT/.perl5/lib/perl5''${PERL5LIB:+:$PERL5LIB}"
    export PERL_LOCAL_LIB_ROOT="$PERL_APP_ROOT/.perl5"
    export PERL_MB_OPT="--install_base \"$PERL_APP_ROOT/.perl5\""
    export PERL_MM_OPT="INSTALL_BASE=$PERL_APP_ROOT/.perl5"
    export PATH="$PERL_APP_ROOT/.perl5/bin:$PATH"
    mkdir -p "$PERL_APP_ROOT/.perl5"
  '';

  # Expose for consumers
  perl = perlPackage;
}
