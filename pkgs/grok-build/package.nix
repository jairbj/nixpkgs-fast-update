{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  autoPatchelfHook,
  versionCheckHook,
}:
let
  sources = lib.importJSON ./sources.json;
  version = sources.version;
  platform = {
    x86_64-linux = "linux-x86_64";
  }.${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-build";
  inherit version;

  strictDeps = true;

  src = fetchurl {
    url = "https://x.ai/cli/grok-${version}-${platform}";
    hash = sources.hash;
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    installShellFiles
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isElf [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/grok"
    ln -s grok "$out/bin/agent"

    ${lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      installShellCompletion --cmd grok \
        --bash <("$out/bin/grok" completions bash) \
        --fish <("$out/bin/grok" completions fish) \
        --zsh <("$out/bin/grok" completions zsh)
    ''}

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  installCheckPhase = ''
    runHook preInstallCheck

    test -L "$out/bin/agent"
    [ "$(readlink -f "$out/bin/agent")" = "$(readlink -f "$out/bin/grok")" ]

    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Command-line coding agent by xAI";
    homepage = "https://docs.x.ai/build/overview";
    downloadPage = "https://x.ai/cli/stable";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
