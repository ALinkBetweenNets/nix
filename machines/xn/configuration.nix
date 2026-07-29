{ self, ... }:
{
  pkgs,
  lib,
  config,
  flake-self,
  home-manager,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModules.home-manager
    # https://github.com/NixOS/nixos-hardware/blob/master/lenovo/thinkpad/x13/yoga/3th-gen/default.nix
    flake-self.inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x13-yoga-3th-gen
  ];
  hardware.enableRedistributableFirmware = true;
  home-manager.users.l = flake-self.homeConfigurations.convertible;
  boot.initrd.systemd.enable = true;
  # systemd.extraConfig = "DefaultLimitNOFILE=2048";
  # security.protectKernelImage = false;
  link = {
    sops = true;
    tailscale-address = "100.108.198.22";
    gaming.enable = true;
    # sway.enable = true;
    # fs.zfs.enable = true;
    printing.enable = true;
    fs.ntfs.enable = true;
    fs.luks.enable = false; # DISABLE BEFORE INSTALL
    convertible.enable = true;
    plymouth.enable = true;
    common.enable = true;
    main.enable = true;
    cpu-intel.enable = true;
    systemd-boot.enable = true;
    #secrets = "/home/l/.keys";
    # wg-link.enable = true;
    domain = "xn.local";
    service-ip = "127.0.0.1";
    # xrdp.enable = true;
    eth = "wlp0s20f3";
    podman.enable = true;
    services.restic-client = {
      enable = true;
      backup-paths-sn = [
        "/home/l/.ssh"
        "/home/l/Documents"
        "/home/l/Pictures"
      ];
      #  backup-paths-sciebo = [
      #    "/home/l/.ssh"
      #    # "/home/l/archive"
      #    "/home/l/doc"
      #    # "/home/l/Documents"
      #    "/home/l/obsidian"
      #    "/home/l/sec"
      #    "/home/l/w"
      #  ];
      #  backup-paths-p4n = [
      #    "/home/l/.ssh"
      #    "/home/l/archive"
      #    "/home/l/doc"
      #    "/home/l/Music"
      #    "/home/l/obsidian"
      #    "/home/l/plasma-vault"
      #    "/home/l/sec"
      #    "/home/l/w"
      #    "/home/l/Pictures"
      #    "/home/l/uni"
      #  ];
    };
  };

  networking.hostId = "007f0200";
  environment.systemPackages = with pkgs; [ kdePackages.plasma-thunderbolt ];
  #services.fprintd = {
  #  enable = true;
  #  tod.enable = true;
  #  tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  #};
  services.fprintd = {
    enable = true;
    # tod.enable = true;
    # tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  };
  networking.firewall.allowedTCPPorts = [ 60955 ];
  networking.firewall.allowedUDPPorts = [ 60955 ];
  networking.hostName = "xn";
  networking.domain = "monitor-banfish.ts.net";
  boot.initrd.kernelModules = [ "psmouse" ];
  services.throttled.enable = lib.mkForce true;
  services.hardware.bolt.enable = lib.mkDefault true;
  hardware.trackpoint.enable = lib.mkDefault true;
  hardware.trackpoint.emulateWheel = lib.mkDefault config.hardware.trackpoint.enable;
  hardware.sensor.iio.enable = true;
  #powerManagement.scsiLinkPolicy = "med_power_with_dipm";
  #environment.systemPackages = with pkgs;    [ ];
  system.stateVersion = "23.11";
}
