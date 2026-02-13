{
  description = "DinoVigilo - Objective Tracker Flutter App";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          build-tools-34-0-0
          build-tools-35-0-0
          build-tools-36-0-0
          platform-tools
          platforms-android-34
          platforms-android-35
          platforms-android-36
          ndk-28-2-13676358
          cmake-3-22-1
          emulator
          system-images-android-34-google-apis-playstore-x86-64
        ]);

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            flutter
            jdk17
            android-sdk
            git
            gh
            curl
            unzip
          ];

          # Libraries needed by the Android emulator's Qt frontend
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            libxkbcommon
            vulkan-loader
            libx11
            libxcb
            libxcb-wm
            libxcb-image
            libxcb-keysyms
            libxcb-render-util
            libxcb-cursor
            wayland
            libGL
          ]);

          NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
          NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            stdenv.cc.cc.lib
            zlib
          ]);

          shellHook = ''
            export ANDROID_HOME="${android-sdk}/share/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
            export JAVA_HOME="${pkgs.jdk17}"
            export FLUTTER_ROOT="${pkgs.flutter}"

            echo "🦖 DinoVigilo Development Environment"
            echo "Flutter: $(flutter --version 2>/dev/null | head -n 1)"
            echo "Android SDK: $ANDROID_HOME"

            flutter doctor

            echo ""
            echo "To create an Android emulator:"
            echo "  avdmanager create avd -n pixel6 -k 'system-images;android-34;google_apis_playstore;x86_64' -d pixel_6"
            echo ""
            echo "To list emulators:"
            echo "  emulator -list-avds"
            echo ""
            echo "To start emulator:"
            echo "  emulator -avd pixel6 &"
            echo ""
            echo "To run the app:"
            echo "  flutter run"
          '';
        };
      });
}
