# iOS development environment helper
{
  pkgs,
  xcodeApp ? "/Applications/Xcode.app",
}: {
  # The iOS SDK only ships inside Xcode.app, so this helper wraps Xcode's own
  # toolchain rather than replacing it. Everything here is CLI only: xcodegen
  # builds the .xcodeproj from a project.yml, xcodes installs Xcode.app without
  # opening it, and the libimobiledevice tools talk to a USB-connected device.
  # xcodegen and xcodes are aarch64-darwin only in nixpkgs.
  packages = [
    pkgs.xcodegen
    pkgs.xcodes
    pkgs.libimobiledevice
    pkgs.ideviceinstaller
    pkgs.fastlane
  ];

  shellHook = ''
    # iOS environment. Build output stays project-local (xcodebuild's
    # DerivedData or -derivedDataPath), so there is no global dir to redirect.
    export IOS_APP_ROOT="$FLAKE_ROOT"

    # The darwin stdenv overwrites these on shell entry with its own
    # macOS-only SDK in the Nix store, so a value the user set never reaches
    # here. xcrun and clang honour them, which would steer an iOS build at the
    # wrong SDK. XCODE_APP is the only way to pick an Xcode.
    unset DEVELOPER_DIR SDKROOT

    # DEVELOPER_DIR does what xcode-select does, without sudo.
    export XCODE_APP="''${XCODE_APP:-${xcodeApp}}"
    if [ -d "$XCODE_APP/Contents/Developer" ]; then
      export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    else
      echo "[ios] Xcode.app not found at $XCODE_APP"
      echo "      Install it without opening the IDE:  xcodes install --latest"
      echo "      Or set XCODE_APP to an existing Xcode.app and re-enter the shell."
    fi
  '';
}
