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
    flake-self.inputs.nixos-hardware.nixosModules.framework-16-7040-amd
    # flake-self.inputs.ucodenix.nixosModules.ucodenix
  ];
  system.autoUpgrade.enable = lib.mkForce false;
  link = {
    hardware.enable=true;
    wg-link.enable = true;
    wg-link.address = "10.5.5.2/24";
    # plymouth.enable = true;
    # hyprland.enable = true;
    sops = true;
    # tailscale-address = "100.108.198.22";
    gaming.enable = true;
    # sway.enable = true;
    # fs.zfs.enable = true;
    printing.enable = true;
    fs.ntfs.enable = true;
    fs.btrfs.enable = true;
    # fs.luks.enable = true;
    laptop.enable = true;
    common.enable = true;
    main.enable = true;
    cpu-amd.enable = true;
    systemd-boot.enable = true;
    #secrets = "/home/l/.keys";
    # wg-link.enable = true;
    domain = "fn.local";
    service-ip = "127.0.0.1";
    # xrdp.enable = true;
    # eth = "wlp0s20f3";
    # nftables.enable = true;
    fail2ban.enable = true;
    podman.enable = true;
    # docker.enable = true;
    i2p.enable = true;
    # services.ollama.enable = true;
    services.restic-client = {
      enable = true;
      backup-paths-sn = [
        "/home/l/.java/.userPrefs"
        "/home/l/.ssh"
        "/home/l/Monero"
        "/home/l/Music"
        "/home/l/Pictures"
        "/home/l/archive"
        "/home/l/camera"
        "/home/l/doc"
        "/home/l/obsidian"
        "/home/l/projects"
        "/home/l/s"
        "/home/l/sec"
        "/home/l/uni"
        "/home/l/w"
      ];
      backup-paths-nn = config.link.services.restic-client.backup-paths-sn;
      #  backup-paths-sciebo = [
      #    "/home/l/.ssh"
      #    # "/home/l/archive"
      #    "/home/l/doc"
      #    # "/home/l/Documents"
      #    "/home/l/obsidian"
      #    "/home/l/sec"
      #    "/home/l/w"
      #  ];
      backup-paths-p4n = [
        "/home/l/.java/.userPrefs"
        "/home/l/.ssh"
        "/home/l/Monero"
        "/home/l/Music"
        "/home/l/Pictures"
        "/home/l/archive"
        "/home/l/camera"
        "/home/l/doc"
        "/home/l/obsidian"
        "/home/l/projects"
        "/home/l/s"
        "/home/l/sec"
        "/home/l/uni"
        "/home/l/w"
      ];
    };
  };
  systemd.services.decrypt-sops = {
    description = "Decrypt sops secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # in network is not ready
      Restart = "on-failure";
      RestartSec = "2s";
    };
    script = config.system.activationScripts.setupSecrets.text;
  };

  containers.tor-container = {
    # autoStart = true;
    config =
      { ... }:
      {
        system.stateVersion = "23.05"; # If you don't add a state version, nix will complain at every rebuild
        # Exposing the nessecary ports in order to interact with i2p from outside the container
        networking.firewall.allowedTCPPorts = [
          9050
          # 7656 # default sam port
          # 7070 # default web interface port
          # 4444 # default http proxy port
          # 4447 # default socks proxy port
        ];
        services.tor = {
          enable = true;
          client.enable = true;
          client.dns.enable = true;
          settings = {
            UseBridges = true;
            ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
            Bridge = "obfs4 IP:ORPort [fingerprint]";
          };
        };
        # services.xrlinuxdriver={
        # enable=true;
        # };
      };
  };
  hardware.enableRedistributableFirmware = true;
  home-manager.users.l = flake-self.homeConfigurations.laptop;
  boot = {
    initrd.systemd.enable = true;
    # kernelParams = [
    #   "btusb.enable_autosuspend=0"
    #   "usbcore.autosuspend=-1"
    # ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    # kernel.sysctl."kernel.sysrq" = 1;
    # Alt+FN+S+key (on other devices Alt+Print+key)
    # h -> help (Output in journal)
    # f -> kernel OOM Killer
    # s -> sync data to disk before reset (REISUB (each key alt+fn+s+key in order) -> Safe reboot)
    # e -> SIGTERM to all processes except PID 0
    # i -> SIGKILL to all processes except PID 0
    # b -> Reboot
    # u -> Remount everything as read only
    # r -> exit Keyboard Raw mode (in case of dead X/Wayland and frozen terminal/ non responsive keyboard)
  };
  #powerManagement.scsiLinkPolicy = "med_power_with_dipm";
  # systemd.extraConfig = "DefaultLimitNOFILE=2048";
  # security.protectKernelImage = false;
  hardware.firmware = [ pkgs.linux-firmware];
  environment.systemPackages = with pkgs; [
    kdePackages.frameworkintegration
    framework-tool-tui
    kdePackages.plasma-thunderbolt
    fw-ectool
    framework-tool
  ];
  services.hardware.bolt.enable = true;
  #services.fprintd = {
  #  enable = true;
  #  tod.enable = true;
  #  tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  #};
  networking = {
    hostId = "007f0200";
    firewall = {
      allowedTCPPorts = [ 60955 ];
      allowedUDPPorts = [ 60955 ];
    };
    hostName = "fn";
    domain = "monitor-banfish.ts.net";
  };
  services.languagetool.enable = true;
  # services.ucodenix = {
  #   enable = true;
  #   cpuSerialNumber =
  #     "00A7-0F41-0000-0000-0000-0000"; # Replace with your processor's serial number
  # };
  system.stateVersion = "23.11";

  # boot.kernelPatches = [
    # {
    #   name = "enable-mt7925e";
    #   patch=null;
    #   structuredExtraConfig=with lib.kernel;{
    #     MT7925E=module;
    #   };
    # }
    # {
    #   name = "mediatek-wifi-fix";
    #   patch = pkgs.fetchpatch {
    #     name = "mediatek-wifi-fix";
    #     url = "https://lore.kernel.org/linux-mediatek/20251009020158.1923429-1-mingyen.hsieh@mediatek.com/raw";
    #     hash = "sha256-BhtGp4YliIIhrqkS09RQfZytKhQwDR3DXM8d7SCJw54=";
    #   };
    # }
  # ];
}
