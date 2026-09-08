{ self, ... }:
{
  config,
  lib,
  pkgs,
  flake-self,
  home-manager,
  mobile-nixos,
  ...
}:
let
  mobileKernel = pkgs.callPackage "${mobile-nixos}/devices/pine64-pinephonepro/kernel" { };
  kernelModuleMakeFlags = import (pkgs.path + "/pkgs/os-specific/linux/kernel/common-flags.nix") {
    inherit lib;
    inherit (pkgs) buildPackages;
    stdenv = mobileKernel.stdenv;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModules.home-manager
  ];
  # Mobile NixOS' kernel builder predates passthru metadata now required by
  # nixpkgs' linuxPackagesFor.
  mobile.boot.stage-1.kernel.package = lib.mkForce (
    mobileKernel.overrideAttrs (
      finalAttrs: old: {
        passthru = old.passthru // {
          dev = finalAttrs.finalPackage;
          commonMakeFlags = kernelModuleMakeFlags;
          isLTS = false;
          isZen = false;
          moduleBuildDependencies = [ ];
        };
      }
    )
  );
  home-manager.users.l = flake-self.homeConfigurations.desktop;
  link = {
    desktop.enable = true;
    syncthing.enable = true;
    plasma.enable = false;
    xserver.enable = false;
    tailscale.enable = true;
  };

  # xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  networking = {
    hostName = "pppn";
    domain = "monitor-banfish.ts.net";
    # Use Network Manager
    # wireless.enable = false; # set via networkmanager
    networkmanager.enable = true;
  };
  hardware = {
    bluetooth.enable = true;
    enableAllFirmware = true;
  };
  services = {
    # hardware.pulseaudio.enable = lib.mkForce true;
    # services.pipewire.enable =  lib.mkForce true;
    # Bluetooth audio
    pulseaudio.package = pkgs.pulseaudioFull;
    xserver.desktopManager.phosh = {
      # Auto-login for phosh
      enable = true;
      user = "l";
      group = "users";
    };
  };
  # Enable power management options
  powerManagement.enable = true;
  # It's recommended to keep enabled on these constrained devices
  zramSwap.enable = true;
  users.users."l" = {
    isNormalUser = true;
    description = "l";
    hashedPassword = "$6$.p.3CNgeNfys/lfs$C5ey0R0CMDlcebtek9bKoCfetajpwmvMG5LqRXzgFGOmLGqsvV.xTVcUtDKtj/c9WJRlv7WDyxIzU2BitOXIy1";
    extraGroups = [
      "dialout"
      "feedbackd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };
}
