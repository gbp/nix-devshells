# iOS development environment helper
{
  pkgs,
  xcodeApp ? "/Applications/Xcode.app",
}: let
  # Release binary, not pkgs.xcodes: nixpkgs lags upstream and old
  # versions cannot sign in to Apple.
  xcodes = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "xcodes";
    version = "2.1.0";

    src = pkgs.fetchurl {
      url = "https://github.com/XcodesOrg/xcodes/releases/download/${finalAttrs.version}/xcodes.zip";
      hash = "sha256-8VGa/pNKUT6F3Zsy/IcjlL7Lu2pB2xXZrDkmoJqJGIg=";
    };

    nativeBuildInputs = [pkgs.unzip pkgs.makeWrapper];
    sourceRoot = ".";

    # Stripping would break Apple's signature on the binary.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -D xcodes $out/bin/xcodes
      wrapProgram $out/bin/xcodes --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.aria2]}
      runHook postInstall
    '';

    meta = {
      description = "Install and switch between multiple versions of Xcode";
      homepage = "https://github.com/XcodesOrg/xcodes";
      changelog = "https://github.com/XcodesOrg/xcodes/releases/tag/${finalAttrs.version}";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.darwin;
      mainProgram = "xcodes";
    };
  });
in {
  # The iOS SDK only ships inside Xcode.app, so this helper wraps Xcode's own
  # toolchain rather than replacing it. Everything here is CLI only: xcodegen
  # builds the .xcodeproj from a project.yml, xcodes installs Xcode.app without
  # opening it, and the libimobiledevice tools talk to a USB-connected device.
  # xcodegen is aarch64-darwin only in nixpkgs.
  packages = [
    pkgs.xcodegen
    xcodes
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
