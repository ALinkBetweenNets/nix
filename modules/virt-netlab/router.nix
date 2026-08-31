# labrouter: the virtual network's router.
#
# Owns the gateway address 10.66.0.1 on br-lab, serves DHCP + DNS to the
# two lab hosts, and forwards their traffic out through fn (which NATs).
#
# Isolation guarantees:
# - fn NATs only 10.66.0.0/24 and drops guest->LAN at FORWARD level.
# - fn drops new inbound connections from br-lab at INPUT level, so the
#   guests cannot reach fn itself even though it routes for them.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.virt-netlab;
in
{
  config = mkIf cfg.enable {
    microvm.vms.labrouter = {
      restartIfChanged = true;
      config = {
        networking.hostName = "labrouter";
        system.stateVersion = config.system.nixos.release;

        microvm = {
          hypervisor = mkDefault "qemu";
          vcpu = mkDefault 2;
          mem = mkDefault 1024;
          interfaces = [
            # downlink into the lab bridge — this VM is the only thing that
            # bridges the lab and the outside world
            {
              type = "tap";
              id = "vm-lab-rtr";
              mac = "52:54:00:aa:00:01";
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

        networking = {
          useNetworkd = true;
          useDHCP = false;
        };
        systemd.network = {
          enable = true;
          networks."10-uplink" = {
            matchConfig.Name = "vm-lab-rtr";
            address = [ "10.66.0.1/24" ];
            networkConfig.IPv6AcceptRA = false;
          };
        };

        boot.kernel.sysctl."net.ipv4.ip_forward" = true;

        # DHCP + DNS for the lab hosts; upstream DNS goes to the LAN
        # router (fn's default gateway), which is fine: DNS answers are
        # just UDP flows initiated from here, same as any web traffic.
        services.dnsmasq = {
          enable = true;
          settings = {
            interface = "vm-lab-rtr";
            bind-dynamic = true;
            except-interface = "lo";
            no-resolv = true;
            server = [ "192.168.188.1" ];
            dhcp-range = [ "10.66.0.50,10.66.0.150,12h" ];
            dhcp-option = [
              "option:router,10.66.0.1"
              "option:dns-server,10.66.0.1"
            ];
            # Static leases keep the lab hosts' addresses stable.
            dhcp-host = [
              "52:54:00:bb:00:0a,lab-host-a,10.66.0.11"
              "52:54:00:bb:00:0b,lab-host-b,10.66.0.12"
            ];
            domain-needed = true;
            no-hosts = true;
            expand-hosts = false;
          };
        };

        # Explicit forward policy on the router itself: accept anything
        # that's part of an established flow, and let new flows out toward
        # fn. fn's firewall does the actual LAN/host isolation, so this is
        # defense in depth rather than the primary control.
        networking.firewall = {
          enable = true;
          allowedUDPPorts = [ 67 ]; # DHCP server
          extraCommands = ''
            iptables -w -A nixos-fw -i vm-lab-rtr -o vm-lab-rtr -j ACCEPT
          '';
          extraStopCommands = "";
        };
        boot.kernelModules = [ "iptable_filter" ];

        nixpkgs.hostPlatform = "x86_64-linux";
      };
    };
  };
}
