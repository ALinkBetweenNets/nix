{ self, ... }:{ pkgs, lib, config, flake-self, home-manager, ... }: {
  imports =
    [ ./hardware-configuration.nix home-manager.nixosModules.home-manager ];
  home-manager.users.l = flake-self.homeConfigurations.convertible;
  link = {
    systemd-boot.enable = true;
    convertible.enable = true;
    main.enable = true;
    cpu-intel.enable = true;
    nvidia.enable = true;
    plasma.enable = false;
    gnome.enable = true;
  };
  networking.hostName = "hn";
  environment.systemPackages = with pkgs; [ ];
  #system.stateVersion = "23.05";
}
