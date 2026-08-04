{
  config,
  pkgs,
  lib,
  flake-self,
  ...
}:
with lib;
let
  cfg = config.link.main;
in
{
  options.link.main = {
    enable = mkEnableOption "activate main";
  };
  config = mkIf cfg.enable {
    link = {
      desktop.enable = true;
      syncthing.enable = true;
      git-sync.enable = true;
      fs.ntfs.enable = true;
      tailscale.enable = true;
      qmk.enable = true;
    };
    services.languagetool = {
      enable = true;
      port = 8082; # internal; clients keep hitting localhost:8081 via the proxy
    };
    systemd.services.languagetool = {
      wantedBy = lib.mkForce [ ]; # don't start at boot
      unitConfig.StopWhenUnneeded = true; # stop once the proxy goes idle
      # gate "started" on the port being up so proxyd doesn't race the JVM
      serviceConfig.ExecStartPost = "${pkgs.bash}/bin/bash -c 'for ((i=0;i<120;i++)); do (echo > /dev/tcp/127.0.0.1/8082) 2>/dev/null && exit 0; ${pkgs.coreutils}/bin/sleep 0.5; done; exit 1'";
    };
    systemd.sockets.languagetool-proxy = {
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "127.0.0.1:8081" ]; # public port, localhost only
    };
    systemd.services.languagetool-proxy = {
      requires = [ "languagetool.service" ];
      after = [ "languagetool.service" ];
      serviceConfig.ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:8082";
    };
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
      usbmon.enable = true;
    };
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [
        # v4l2loopback # broken
      ];
      kernelModules = [
        "ntsync"
        # "v4l2loopback" # broken
      ];
    };
    services.rpcbind.enable = true; # for NFS
    # services.pcscd.enable = true; # smart card support
    services = {
      #teamviewer.enable = true;
      mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn; # gui version
      };
      udev = {
        # packages = [ pkgs.android-udev-rules ];
        enable = true;
      };
    };
    environment.wordlist.enable = true;
    environment.wordlist.lists = {
      WORDLIST = [
        "${pkgs.scowl}/share/dict/words.txt"
        "${pkgs.seclists}/share/wordlists/seclists"
      ];
      AUGMENTED_WORDLIST = [
        "${pkgs.scowl}/share/dict/words.txt"
        "${pkgs.scowl}/share/dict/words.variants.txt"
        (builtins.toFile "extra-words" ''
          desynchonization
          oobleck'')
      ];
    };
    environment.systemPackages = with pkgs; [
      flake-self.inputs.compose2nix.packages.x86_64-linux.default
      flake-self.inputs.nsearch.packages.${pkgs.stdenv.hostPlatform.system}.default
      bun
      kdePackages.plasma-thunderbolt
      aha # for kde settings
      clinfo
      vulkan-tools
      # ondsel # Better FreeCAD
      sshfs
      rclone
      ddcui
      ddcutil
      android-tools
      cpio
      net-tools
      link.precomp
    ];
    services.netbird.enable = true;
    systemd.services.netbird.wantedBy = lib.mkForce [ ];
    hardware.i2c.enable = true;
    users.groups.i2c = { };
    services.udev.packages = with pkgs; [ ddcutil ];
    hardware.hackrf.enable = true;
    programs = {
      appimage = {
        enable = true;
        binfmt = true;
      };
      noisetorch.enable = true;
      ausweisapp = {
        enable = true;
        openFirewall = true;
      };
      obs-studio = {
        enable = true;
        enableVirtualCamera = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-websocket
          obs-vaapi
          obs-teleport
          obs-composite-blur
          obs-backgroundremoval
        ];
      };
    };
    # virtualisation.waydroid.enable = true;
    networking.firewall.allowedTCPPorts = [ 24800 ];
    # networking.networkmanager.appendNameservers = [
    #   "1.1.1.1"
    #   "192.168.178.1"
    #   "9.9.9.9"
    #   "216.146.35.35"
    #   "2620:fe::fe"
    #   "2606:4700:4700::1111"
    # ];
    # services.udev.extraRules = ''
    #   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="$USER_GID", TAG+="uaccess", TAG+="udev-acl"
    #   KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", MODE=\"0660\", GROUP=\"$USER_GID\", TAG+=\"uaccess\", TAG+=\"udev-acl\"
    # '';
  };
}
