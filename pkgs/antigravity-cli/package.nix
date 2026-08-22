{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:
let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version buildId;
  # Upstream URLs embed an opaque build id alongside the version.
  wholeVersion = "${version}-${buildId}";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "antigravity-cli";
  inherit version;

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
    hash = sources.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isElf [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 antigravity $out/bin/agy

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru = {
    inherit wholeVersion; # for the updateScript
    updateScript = ./update.sh;
  };

  meta = {
    description = "Google's Go-based terminal user interface (TUI) agent client";
    homepage = "https://antigravity.google";
    changelog = "https://antigravity.google/changelog";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
