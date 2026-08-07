{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeBinaryWrapper,
  autoPatchelfHook,
  alsa-lib,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  manifest ? lib.importJSON ./manifest.json,
}:
let
  stdenv = stdenvNoCC;
  baseUrl = "https://downloads.claude.ai/claude-code-releases";
  # Bootstrap targets x86_64-linux only; platform key matches Anthropic's layout.
  platformKey = "linux-x64";
  platformManifestEntry =
    manifest.platforms.${platformKey}
      or (throw "claude-code: platform ${platformKey} missing from manifest.json");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  inherit (manifest) version;

  src = fetchurl {
    url = "${baseUrl}/${finalAttrs.version}/${platformKey}/claude";
    sha256 = platformManifestEntry.checksum;
  };

  dontUnpack = true;
  dontBuild = true;
  # otherwise the bun runtime is executed instead of the binary
  dontStrip = true;

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  strictDeps = true;

  installPhase = ''
    runHook preInstall

    installBin $src

    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ alsa-lib ]} \
      --prefix PATH : ${
        lib.makeBinPath [
          # claude-code uses node-tree-kill which requires procps
          procps
          # https://code.claude.com/docs/en/troubleshooting#search-and-discovery-issues
          ripgrep
          # sandbox support on Linux
          bubblewrap
          socat
        ]
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://claude.com/product/claude-code";
    changelog = "https://github.com/anthropics/claude-code/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
})
