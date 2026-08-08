{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  versionCheckHook,
  # Bundled node + native modules need these.
  libsecret,
  libX11,
  libxkbfile,
  dbus,
  curl,
  openssl,
  util-linux,
  glib,
}:
let
  sources = lib.importJSON ./sources.json;
  version = sources.version;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "code-server";
  inherit version;

  strictDeps = true;

  src = fetchurl {
    url = "https://github.com/coder/code-server/releases/download/v${version}/code-server-${version}-linux-amd64.tar.gz";
    hash = sources.hash;
  };

  # Keep bundled node and native addons intact.
  dontStrip = true;
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libsecret
    libX11
    libxkbfile
    dbus
    curl
    openssl
    util-linux
    glib
  ];

  # Optional Microsoft auth extension pulls desktop/WebKit deps we do not ship
  # on a headless code-server install.
  autoPatchelfIgnoreMissingDeps = [
    "libwebkit2gtk-4.1.so.0"
    "libgtk-3.so.0"
    "libgdk-3.so.0"
    "libsoup-3.0.so.0"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/code-server
    cp -a . $out/lib/code-server

    # Official wrapper is a shell script that needs coreutils (dirname/basename).
    # Invoke the bundled node the same way: node <app-root> [args...]
    makeBinaryWrapper $out/lib/code-server/lib/node $out/bin/code-server \
      --add-flags $out/lib/code-server

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Run VS Code on a remote server";
    longDescription = ''
      code-server is VS Code running on a remote server, accessible through the
      browser. This package uses the official prebuilt linux-amd64 release.
    '';
    homepage = "https://github.com/coder/code-server";
    changelog = "https://github.com/coder/code-server/releases/tag/v${version}";
    downloadPage = "https://github.com/coder/code-server/releases";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "code-server";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
