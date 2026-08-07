{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:
let
  sources = lib.importJSON ./sources.json;
  version = sources.version;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pad";
  inherit version;

  strictDeps = true;

  src = fetchurl {
    url = "https://github.com/PerpetualSoftware/pad/releases/download/v${version}/pad_${version}_linux_amd64.tar.gz";
    hash = sources.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isElf [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 pad $out/bin/pad

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Project Management for the agent era";
    homepage = "https://github.com/PerpetualSoftware/pad";
    changelog = "https://github.com/PerpetualSoftware/pad/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pad";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
