{ self, ... }:{ pkgs, lib, config, flake-self, home-manager, ... }: {
  imports =
    [ ./hardware-configuration.nix home-manager.nixosModules.home-manager ];
  home-manager.users.l = flake-self.homeConfigurations.tower;
  link = {
    sops = true;
    tailscale-address = "100.119.237.77";
    gaming.enable = true;
    systemd-boot.enable = true;
    tower.enable = true;
    main.enable = true;
    # printing.enable = lib.mkDefault true;
    cpu-intel.enable = true;
    nvidia.enable = true;
    secrets = "/home/l/.keys";
    # wg-link.enable = true;
    xserver.enable = true;
    eth = "enp111s0";
    domain = "dn.local"; # testing domain
    # home-assistant.enable = true;
    docker.enable = true;
    syncthing.enable = lib.mkForce false;
    services = {
      # ollama.enable = true;
      # matrix.enable = true;
      # immich.enable = true;
      restic-client = {
        enable = true;
        backup-paths-sn = [
          # "/home/l/.config"
          "/home/l/.ssh"
          "/home/l/Documents"
          "/home/l/Pictures"
          # "/home/l/plasma-vault"
        ];
        # backup-paths-p4n = [
        #   "/home/l/.config"
        #   "/home/l/.ssh"
        #   "/home/l/archive"
        #   "/home/l/doc"
        #   "/home/l/Documents"
        #   "/home/l/obsidian"
        #   "/home/l/plasma-vault"
        #   "/home/l/sec"
        #   "/home/l/w"
        # ];
      };
    };
  };
  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb;

  };
  networking = {
    hostName = "dn";
    domain = "monitor-banfish.ts.net";
    hostId = "007f0200";
    # interfaces."${config.link.eth}".wakeOnLan.enable = true;
  };
  # services.xserver.wacom.enable = true;
  # environment.systemPackages = with pkgs; [ wacomtablet xf86_input_wacom ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
