# Arduino development environment helper
{
  pkgs,
  boardUrls ? [],
  cores ? [],
  libraries ? [],
  package ? null,
}: let
  inherit (pkgs) lib;
  arduinoPackage =
    if package != null
    then package
    else if pkgs.stdenv.hostPlatform.isLinux
    then
      # Core build scripts such as the ESP8266 ones call /usr/bin/python3,
      # which the nixpkgs FHS env does not provide.
      pkgs.buildFHSEnv {
        inherit (pkgs.arduino-cli) pname version meta;
        runScript = "${pkgs.arduino-cli.pureGoPkg}/bin/arduino-cli";
        targetPkgs = p: [p.zlib p.python3];
      }
    else pkgs.arduino-cli;
  specHash = builtins.substring 0 16 (builtins.hashString "sha256" (builtins.toJSON {
    inherit boardUrls cores libraries;
    inherit (pkgs.stdenv.hostPlatform) system;
  }));
in {
  packages = [arduinoPackage];

  shellHook =
    ''
      # Arduino environment - uses $FLAKE_ROOT for cores and libraries
      export ARDUINO_APP_ROOT="$FLAKE_ROOT"
      export ARDUINO_DIRECTORIES_DATA="$ARDUINO_APP_ROOT/.arduino15"
      export ARDUINO_DIRECTORIES_DOWNLOADS="$ARDUINO_DIRECTORIES_DATA/staging"
      export ARDUINO_DIRECTORIES_USER="$ARDUINO_APP_ROOT/.arduino"
      export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS=${lib.escapeShellArg (lib.concatStringsSep " " boardUrls)}
    ''
    + lib.optionalString (cores != [] || libraries != []) ''
      _arduino_stamp="$ARDUINO_DIRECTORIES_DATA/.installed-${specHash}"
      if [ ! -f "$_arduino_stamp" ]; then
        if arduino-cli core update-index \
          ${lib.optionalString (cores != []) "&& arduino-cli core install ${lib.escapeShellArgs cores}"} \
          ${lib.optionalString (libraries != []) "&& arduino-cli lib install ${lib.escapeShellArgs libraries}"}
        then
          touch "$_arduino_stamp"
        else
          echo "withArduino: install failed, it will retry on next shell entry" >&2
        fi
      fi
    '';

  # Expose for consumers
  arduino-cli = arduinoPackage;
}
