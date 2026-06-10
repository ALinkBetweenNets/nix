{ config, system-config, pkgs, lib, adblock-unbound, ... }:
with lib;
let
  cfg = config.link.unbound;
  adlist = adblock-unbound.packages.${pkgs.stdenv.hostPlatform.system};
  dns-overwrites-config = builtins.toFile "dns-overwrites.conf" (''
    # DNS overwrites
  '' + concatStringsSep "\n"
    (mapAttrsToList (n: v: ''local-data: "${n} A ${toString v}"'')
      cfg.A-records));
in {
  options.link.unbound = {
    enable = mkEnableOption "activate unbound";
    A-records = mkOption {
      type = types.attrs;
      default = {
        "pass.telekom.de" = "109.237.176.33";
        "smokeping.lounge.rocks" = "192.168.5.21";
        "c" = "10.5.5.1";
        "f" = "10.5.5.2";
        "n" = "10.5.5.6";
        "s" = "10.5.5.5";
      };
      description = ''
        Custom DNS A records
      '';
    };
  };
  config = mkIf cfg.enable {
    # link.dns.enable = lib.mkDefault true;
    services.unbound = {
      enable = true;
      localControlSocketPath = "/run/unbound/unbound.ctl";
      resolveLocalQueries = false;
      settings = {
        server = {
          include = [
            ''"${dns-overwrites-config}"''
            ''"${adlist.unbound-adblockStevenBlack}"''
          ];
          interface = [ "::1" "127.0.0.1" ];
          access-control = [ "127.0.0.0/8 allow" ];
          # verbosity=3;
          # log-queries="yes";
          # log-replies="yes";
          # module-config="iterator";
          val-permissive-mode="yes";
        };
        # forward local DNS requests via Wireguard
        # domain-insecure = [ "haus" ];
        # stub-zone = [
        #   {
        #     name = "haus";
        #     stub-addr = "10.88.88.4";
        #   }
        # ];
        forward-zone = [
          { name = "iceportal.de.";
            forward-addr =[ "172.18.1.110" "2620:fe::fe@853#dns.quad9.net"];
          }{ name = "wifionice.de.";
              forward-addr =["172.18.0.1" "2620:fe::fe@853#dns.quad9.net"];
          }{ name = "omboard.info.";
              forward-addr =["172.18.0.1" "2620:fe::fe@853#dns.quad9.net"];
          # }{ name = "bahn.de.";
             # forward-addr =[ "172.18.0.1" "2620:fe::fe@853#dns.quad9.net"];
          }
          {
            name = "monitor-banfish.ts.net.";
            forward-addr = [ "100.100.100.100" ];
            forward-tls-upstream = "no";
          }
          {
            name = "mullvad.net.";
            forward-addr = [ "194.242.2.2@853#dns.mullvad.net" ];
            forward-tls-upstream = "yes";
          }
          {
            name = "lsec.ninja.";
            forward-addr = [ "100.121.15.22" ];
            forward-tls-upstream = "no";
          }
          {
            name = "lsec.vpn.";
            forward-addr = [ "10.100.11.1" ];
            forward-tls-upstream = "no";
          }
          {
            name = "google.*.";
            forward-addr =
              [ "8.8.8.8@853#dns.google" "8.8.8.4@853#dns.google" ];
            forward-tls-upstream = "yes";
          }
          {
            name = "youtube.*.";
            forward-addr =
              [ "8.8.8.8@853#dns.google" "8.8.8.4@853#dns.google" ];
            forward-tls-upstream = "yes";
          }
          {
            name = ".";
            forward-addr = [
              # "192.168.1.1"
              # "192.168.178.1"
              #"10.100.11.1"
              # "100.100.100.100" # tailscale
              "76.76.2.11#p2.freedns.controld.com"
              "2606:1a40::11#p2.freedns.controld.com"
              # "2620:fe::fe@853#dns.quad9.net"
              "2620:fe::9@853#dns.quad9.net"
              # "9.9.9.9#dns.quad9.net" # quad9
              # "149.112.112.112#dns.quad9.net"
              # "2a07:e340::4#base.dns.mullvad.net"
              # "194.242.2.4#base.dns.mullvad.net"
              # "192.168.188.3" # npo
              # "2a09::@853" # dns.sb
              "2a11::@853" # dns.sb
              # "185.222.222.222@853" # dns.sb
              # "45.11.45.11@853" # dns.sb
              # "8.8.8.8" # google
              # "2606:4700:4700::1111@853#cloudflare-dns.com"
              # "1.1.1.1@853#cloudflare-dns.com"
              # "2606:4700:4700::1001@853#cloudflare-dns.com"
              # "1.0.0.1@853#cloudflare-dns.com"
              # "1.0.0.1" # cloudflare
              # "194.242.2.2" # mullvad
            ];
            # forward-first = "yes";
            forward-tls-upstream = "yes";
          }
        ];
      };
    };
  };
}
