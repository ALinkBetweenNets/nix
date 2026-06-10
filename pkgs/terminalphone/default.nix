{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  tor,
  socat,
  openssl,
  opusTools,
  sox,
  alsaUtils,
}:

stdenv.mkDerivation {
  pname = "terminalphone";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "edengilbertus";
    repo = "terminalphone";
    rev = "a1f9a8f85154aed3c8fecc6964bbaf8b22924943";
    hash = "sha256-8n5Uld1ngIY9nXOiYKJ7m+ikgwZxaukuqA3421GZG+k=";
  };

  nativeBuildInputs = [ makeWrapper ];

  patchPhase = ''
    substituteInPlace terminalphone.sh \
      --replace-fail 'DATA_DIR="$BASE_DIR/.terminalphone"' \
                     'DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/terminalphone"'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 terminalphone.sh $out/bin/terminalphone
    wrapProgram $out/bin/terminalphone \
      --prefix PATH : ${lib.makeBinPath [
        tor
        socat
        openssl
        opusTools
        sox
        alsaUtils
      ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Encrypted push-to-talk voice and text communication over Tor";
    homepage = "https://github.com/edengilbertus/terminalphone";
    license = licenses.mit;
    mainProgram = "terminalphone";
    platforms = platforms.linux;
  };
}
