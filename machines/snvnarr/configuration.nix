{ self, ... }:{ pkgs, lib, config, flake-self, home-manager, ... }: {
  imports =
    [ ./hardware-configuration.nix home-manager.nixosModules.home-manager ];
  home-manager.users.l = flake-self.homeConfigurations.server;
  link = {
    arr.enable = true;
    systemd-boot.enable = false;
    grub.enable = true;
    vm.enable = true;
    storage = "/arr";
    tailscale.enable = true;
    tailscale.routing = "server";
  };
  users.users.l.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF+rCKg9anv0pU96BL0cUcbKU8w1q75kt+JGroJcE19 l@sn"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF+rCKg9anv0pU96BL0cUcbKU8w1q75kt+JGroJcE19 l@sn"
  ];
  networking.hostName = "snvnarr";
  boot.loader.grub.device = "/dev/vda";
  services.mullvad-vpn.enable = true;
  # services.mullvad-vpn.package = pkgs.mullvad-vpn; # gui version
  fileSystems."arra" = {
    device = "arra"; # Replace with the correct device or path
    fsType = "9p"; # Replace with the filesystem type
    mountPoint = "${config.link.storage}";
    options = [ "trans=virtio" ];
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" ];
  };
}
