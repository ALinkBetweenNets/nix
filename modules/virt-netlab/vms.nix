# The two lab hosts. Plain NixOS microvms on the lab bridge; they get
# their address from labrouter's DHCP and have no other network access
# than what the router allows.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.virt-netlab;

  mkLabHost =
    name: index:
    { config, ... }:
    {
      networking.hostName = name;
      system.stateVersion = config.system.nixos.release;

      microvm = {
        hypervisor = mkDefault "qemu";
        vcpu = mkDefault 1;
        mem = mkDefault 512;
        interfaces = [
          {
            type = "tap";
            id = "vm-lab-h${index}";
            mac = "52:54:00:bb:00:${index}";
          }
        ];
        shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }
        ];
      };

      networking.useDHCP = true;
      # microvm.nix optimization defaults already give us networkd.

      environment.systemPackages = with pkgs; [
        curl
        iputils
        dnsutils
      ];

      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "prohibit-password";
      };
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLbcnlo7XXvk8qH2mqMC3jzrrTVjfqTwRHuyrMwPHHf l@fn"
      ];

      nixpkgs.hostPlatform = "x86_64-linux";
    };
in
{
  config = mkIf cfg.enable {
    microvm.vms = {
      "lab-host-a" = {
        config = mkLabHost "lab-host-a" "0a";
      };
      "lab-host-b" = {
        config = mkLabHost "lab-host-b" "0b";
      };
    };
  };
}
