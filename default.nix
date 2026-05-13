let
  pkgs = import <nixpkgs> { };

  cli-bin = pkgs.callPackage (
    {
      lib,
      stdenv,
      cmake,
      makeWrapper,
      openssl,
      xz,
      python3,
    }:

    stdenv.mkDerivation (finalAttrs: {
      pname = "chameleon-cli-bin";
      version = "0";

      src = ./software/src;

      postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace-fail "liblzma" "lzma" \
          --replace-fail "FetchContent_MakeAvailable(xz)" "" \
          --replace-fail "\''${CMAKE_CURRENT_SOURCE_DIR}/../script/bin" "$out/bin"
      '';

      nativeBuildInputs = [
        cmake
        makeWrapper
      ];

      buildInputs = [
        openssl
        xz
      ];

      dontInstall = true;
    })
  ) { };

  python3 = pkgs.python3.withPackages (
    p: with p; [
      colorama
      prompt-toolkit
      pyserial
    ]
  );

  cli = pkgs.writeShellScriptBin "chemaleon-cli" ''
    set -euo pipefail

    cli_file=software/script/chameleon_cli_main.py
    bin_dir=software/script/bin

    if [ ! -e "$cli_file" ]; then
      echo "$cli_file does not exist, need to run in ChameleonUltra dir" >&2
      exit 1
    fi

    if [ ! -e "$bin_dir" ] || [ "$(readlink -f "$bin_dir")" != "${cli-bin}/bin" ]; then
      ln -sf "${cli-bin}/bin" "$bin_dir"
    fi

    ${pkgs.lib.getExe python3} "$cli_file" "$@"
  '';
in

cli
// {
  inherit python3;
}
