inputs: self: super: {
  # our packages are accessible via link.<name>
  link = {
    candy-icon-theme = super.callPackage ./candy-icon-theme { };
    oblivian-server = super.callPackage ./oblivian { };
    precomp = super.callPackage ./precomp { };
    terminalphone = super.callPackage ./terminalphone {
      alsaUtils = super.alsa-utils;
      opusTools = super.opus-tools;
    };
  };
}
