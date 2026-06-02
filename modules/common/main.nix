{
  config,
  pkgs,
  lib,
  flake-self,
  helix-notes,
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
      kdePackages.plasma-thunderbolt
      aha # for kde settings
      clinfo
      vulkan-tools
      # ondsel # Better FreeCAD
      sshfs
      rclone
      ddcui
      ddcutil
      networkmanager-openvpn
      android-tools
      cpio
      net-tools
      link.precomp
      (helix-notes.packages.${pkgs.stdenv.hostPlatform.system}.default)
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
