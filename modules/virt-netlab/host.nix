# Virtual network lab: host-side plumbing.
#
# Topology (all inside the laptop, isolated from LAN and host):
#
#   [host-a 10.66.0.11]---tap---\
#                                [br-lab]---[labrouter 10.66.0.1]---NAT---wlp1s0
#   [host-b 10.66.0.12]---tap---/
#
# - br-lab is an internal bridge: it has NO physical port, so the only way
#   in or out is through labrouter, which owns the gateway address.
# - NetworkManager must not touch the bridge or taps (unmanaged).
# - NAT is scoped to 10.66.0.0/24 via internalIPs; forwarding for that
#   subnet comes from nat-iptables' nixos-filter-forward chain.
# - The router microvm's firewall drops everything from br-lab toward the
#   host/LAN side except established flows and DNS/DHCP service answers.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.virt-netlab;

  # lab subnet, kept out of the way of virbr*/docker/tailscale ranges
  lab-subnet = "10.66.0.0/24";
  lan-subnet = "192.168.188.0/24";
  wan-if = "wlp1s0";
in
{
  options.link.virt-netlab = {
    enable = mkEnableOption "virtual network lab (router + 2 isolated hosts as microvms)";
  };

  config = mkIf cfg.enable {
    # NOTE: no need to touch `microvm.autostart` — microvm.nix's host
    # module derives it automatically from the per-VM `autostart` flag,
    # which defaults to true for every declarative VM.

    boot.kernelModules = [ "bridge" ];

    networking = {
      # The bridge and tap devices belong to networkd + microvm.nix.
      # NM would otherwise try to DHCP/manage them.
      networkmanager.unmanaged = [
        "br-lab"
        "vm-lab-*"
      ];

      nat = {
        enable = true;
        internalIPs = [ lab-subnet ];
        externalInterface = wan-if;
      };

      firewall = {
        # Router serves DHCP+DNS on br-lab.
        allowedUDPPorts = [
          53
          67
        ];
        allowedTCPPorts = [ 53 ];
        extraCommands = mkMerge [
          ''
            # Guests may reach anything EXCEPT the LAN. wlp1s0 carries the
            # LAN subnet, so block it at FORWARD level. (Host protection is
            # handled separately on the INPUT chain below.) These rules are
            # appended to nixos-filter-forward, which nat-iptables creates.
            iptables -w -A nixos-filter-forward -i br-lab -o ${wan-if} -d ${lan-subnet} -j DROP
            ip6tables -w -A nixos-filter-forward -i br-lab -o ${wan-if} -d fe80::/10 -j DROP
            ip6tables -w -A nixos-filter-forward -i br-lab -o ${wan-if} -d fc00::/7 -j DROP
          ''
          (mkAfter ''
            # The lab bridge has no uplink, so nothing on fn should ever
            # receive new connections from it. Enforce on INPUT: drop
            # everything from br-lab unless it belongs to an established
            # flow (e.g. a reply to a guest's outbound HTTP request).
            iptables -w -A nixos-fw -i br-lab -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept
            iptables -w -A nixos-fw -i br-lab -j nixos-fw-refuse
            ip6tables -w -A nixos-fw -i br-lab -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept
            ip6tables -w -A nixos-fw -i br-lab -j nixos-fw-refuse
          '')
        ];
      };
    };

    systemd.network = {
      enable = true;
      wait-online.anyInterface = true;

      netdevs."40-br-lab" = {
        netdevConfig = {
          Name = "br-lab";
          Kind = "bridge";
        };
      };
      networks."40-br-lab-ports" = {
        matchConfig.Name = "vm-lab-*";
        networkConfig.Bridge = "br-lab";
      };
    };

    virtualisation.libvirtd.enable = mkForce false;
  };
}
