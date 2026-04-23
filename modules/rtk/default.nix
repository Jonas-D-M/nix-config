{
  pkgs,
  lib,
  ...
}:
let
  version = "0.37.2";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-aarch64-apple-darwin.tar.gz";
      hash = "sha256-meIKWYR97btkAyo/eYXy/pWfy5Z02Or5QPxYoYnifso=";
    };
    x86_64-darwin = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-apple-darwin.tar.gz";
      hash = "sha256-QFLndAqH4SH2caLeJps/AV3MWLYXHWvtswDadZnLTZQ=";
    };
    x86_64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-Pft6BWNqaGh7ocWqaW+o1fy0lER97YbZ64uItxAKN8Y=";
    };
    aarch64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-HY1/zKbLBeGGfAi7Tlql8QfAN8YHEx5RG3Jq4zrDWkc=";
    };
  };

  system = pkgs.stdenv.hostPlatform.system;

  rtk = pkgs.stdenvNoCC.mkDerivation {
    pname = "rtk";
    inherit version;

    src = pkgs.fetchurl sources.${system};
    sourceRoot = ".";

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];

    installPhase = ''
      runHook preInstall
      install -Dm755 rtk $out/bin/rtk
      runHook postInstall
    '';

    meta = {
      description = "CLI proxy that reduces LLM token consumption by 60-90%";
      homepage = "https://github.com/rtk-ai/rtk";
      license = lib.licenses.mit;
      platforms = builtins.attrNames sources;
      mainProgram = "rtk";
    };
  };
in
{
  home.packages = [ rtk ];
  home.sessionVariables.RTK_TELEMETRY_DISABLED = "1";
}
