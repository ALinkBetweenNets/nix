inputs: self: super: {
  # our packages are accessible via link.<name>
  link = {
    candy-icon-theme = super.callPackage ./candy-icon-theme { };
    flux2-klein = super.callPackage ./flux2-klein { };
    oblivian-server = super.callPackage ./oblivian { };
    precomp = super.callPackage ./precomp { };
    terminalphone = super.callPackage ./terminalphone {
      alsaUtils = super.alsa-utils;
      opusTools = super.opus-tools;
    };
    wifit3 = super.callPackage ./wifit3 { };
  };
  hermes-agent = inputs.hermes-agent.packages.${super.stdenv.hostPlatform.system}.default;
}
