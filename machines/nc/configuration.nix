# 202.61.251.70
#	2a03:4000:54:8a::/64
# nix run github:numtide/nixos-anywhere -- --flake .#nc root@202.61.251.70
{ self, ... }:
let
  # common extra config for geoip blocking, redirects to get rotated idiot
  # default_type text/html;
  # access_log /var/log/nginx/access.log;
  # access_log /var/log/nginx/blocked.log body if=$blocked_country;
  commonExtraConfig = ''
    if ($blocked_country) {
      return 307 https://www.youtube.com/watch?v=iA4LKxj81zc;
    }
  '';
  # echo_read_request_body;
  commonLocationExtraConfig = "";
  # error_page 404 403 @redirect404;
  # location @redirect404 {
  #   return 307 https://www.youtube.com/watch?v=dQw4w9WgXcQ;
  # }
in
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
    ./netcup.nix
    home-manager.nixosModules.home-manager
  ];
  home-manager.users.l = flake-self.homeConfigurations.server;
  link = {
    wg-link-server.enable = true;
    wg-luks-server.enable = true;
    sops = true;
    tailscale-address = "100.86.79.82";
    common.enable = true;
    eth = "ens3";
    domain = "alinkbetweennets.de";
    fail2ban.enable = true;
    nginx.enable = true;
    nginx.geoIP = true;
    serviceHost = "100.108.233.76";
    server.enable = true;
    vm.enable = true;
    # services.coturn.enable = true;
  };
  sops.secrets."cloudflare-api" = { };
  security.acme = {
    acceptTerms = true;
    defaults.email = "link2502+acme" + "@" + "proton.me";
    defaults.webroot = "/var/lib/acme/acme-challenge";
    certs."${config.link.domain}" = {
      domain = config.link.domain;
      extraDomainNames = [ "*.${config.link.domain}" ];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare-api".path;
      webroot = null;
    };
    certs."alinkbn.de" = {
      domain = config.link.domain;
      extraDomainNames = [ "*.alinkbn.de" ];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare-api".path;
      webroot = null;
    };
  };
  boot.kernel.sysctl = {
    # ctf vpn forwarding
    "net.ipv4.conf.tailscale0.forwarding" = true;
    "net.ipv6.conf.tailscale0.forwarding" = true;
    "net.ipv4.conf.ens3.forwarding" = true;
    "net.ipv6.conf.ens3.forwarding" = true;
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.ip_forward" = lib.mkForce 1;
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = config.link.eth;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.nat = {
    enable = true;
    externalInterface = config.link.eth;
    # externalIP = "202.61.251.70";
    internalInterfaces = [
      "tailscale0"
      config.link.eth
    ];
    # internalIPs = [ "192.168.2.15/32" "100.87.16.37/32" ];
    enableIPv6 = true;
    forwardPorts = [
      {
        sourcePort = 3478;
        proto = "tcp";
        destination = "${config.link.serviceHost}:3478";
        loopbackIPs = [ "100.87.16.37" ];
      }
      # {
      #   sourcePort = 80;
      #   proto = "tcp";
      #   destination = "${config.link.serviceHost}:80";
      #   loopbackIPs = [ "100.87.16.37" ];
      # }
      # {
      #   sourcePort = 443;
      #   proto = "tcp";
      #   destination = "${config.link.serviceHost}:443";
      #   loopbackIPs = [ "100.87.16.37" ];
      # }
      # {
      #   sourcePort = 80;
      #   proto = "udp";
      #   destination = "${config.link.serviceHost}:80";
      #   loopbackIPs = [ "100.87.16.37" ];
      # }
      # {
      #   sourcePort = 443;
      #   proto = "udp";
      #   destination = "${config.link.serviceHost}:443";
      #   loopbackIPs = [ "100.87.16.37" ];
      # }
      {
        sourcePort = 51821;
        proto = "udp";
        destination = "192.168.2.15:51821";
        loopbackIPs = [ "100.87.16.37" ];
      }
      {
        sourcePort = 51820;
        proto = "udp";
        destination = "192.168.2.15:51820";
        loopbackIPs = [ "100.87.16.37" ];
      }
      {
        sourcePort = 41623;
        proto = "tcp";
        destination = "192.168.2.15:41623";
        loopbackIPs = [ "100.87.16.37" ];
      }
    ];
  };
  # networking.nat = {
  #   enable = true;
  #   externalInterface = "ens3";
  #   externalIP = "202.61.251.70";
  #   internalInterfaces = [ "tailscale0" ];
  #   internalIPs = [ "100.89.40.41/32" "100.89.178.137/32" ];
  #   forwardPorts = [
  #     { sourcePort = 443; proto = "tcp"; destination = "100.89.178.137:443"; loopbackIPs = [ "100.86.79.82" ]; }
  #   ];
  # };
  networking = {
    firewall.allowedTCPPorts = [
      41623
      8920
      8096
    ];
    firewall.allowedUDPPorts = [
      51820
      51821
      51822
    ];
    hostName = "v2202312204123249185";
    domain = "ultrasrv.de";
    interfaces."ens3" = {
      ipv6.addresses = [
        {
          address = "2a03:4000:54:8a:585a:48ff:fee3:9d06";
          prefixLength = 64;
        }
      ];
    };
  };
  services.nginx.virtualHosts = {

    # "grist.${config.link.domain}" = {
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8484";
    #     proxyWebsockets = true;
    #   };
    # };
    # services.nginx.virtualHosts."diagrams.${config.link.domain}" = {
    #   enableACME = true;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://127.0.0.1:8765";
    #     proxyWebsockets = true;
    #   };
    #   # extraConfig = mkIf (!cfg.expose) ''
    #   #   allow ${config.link.service-ip}/24;
    #   #     allow 127.0.0.1;
    #   #     deny all; # deny all remaining ips
    #   # '';
    # };
    # "matrix.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${
    #       toString config.link.services.matrix.port
    #     }";
    #   locations."/".proxyWebsockets = true;
    # };
    # "vikunja.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${
    #       toString config.link.services.vikunja.port
    #     }";
    #   locations."/".proxyWebsockets = true;
    # };
    # "gitea.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${
    #         toString config.services.gitea.settings.server.HTTP_PORT
    #       }";
    #     proxyWebsockets = true;
    #   };
    # };
    "radicale.${config.link.domain}" = {
      # needed for family
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:${toString config.link.services.radicale.port}";
        proxyWebsockets = true;
      };
    };
    # "widdycustomsend.${config.link.domain}"={
    #   useACMEHost = config.link.domain;
    #   forceSSL = true;
    #   extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = ''
    #       auth_basic "hi there sweetheart";
    #       auth_basic_user_file /var/abc.txt;
    #     '';
    #     proxyPass = "http://sn:61341";
    #     proxyWebsockets = true;
    #   };
    # };
    # "keycloak.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    #extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass =
    #       "http://100.98.35.19:${toString config.link.services.keycloak.port}";
    #     proxyWebsockets = true;
    #   };
    # };
    # "keycloak.alinkbn.de" = {
    #   # enableACME = true;
    #   useACMEHost = "alinkbn.de";
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass =
    #       "http://100.98.35.19:${toString config.link.services.keycloak.port}";
    #     proxyWebsockets = true;
    #   };
    # };
    # "grafana.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass =
    #       "http://100.98.35.19:${toString config.link.services.grafana.port}/";
    #     proxyWebsockets = true;
    #   };
    # };
    # "grafana.alinkbn.de" = {
    #   # enableACME = true;
    #   useACMEHost = "alinkbn.de";
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass =
    #       "http://100.98.35.19:${toString config.link.services.grafana.port}/";
    #     proxyWebsockets = true;
    #   };
    # };
    "gitlab.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        # proxy_set_header Host              $host;
        extraConfig = commonLocationExtraConfig + ''
          proxy_set_header X-Real-IP         $remote_addr;
          proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-Ssl   on;
          proxy_set_header X-Forwarded-Port  443;
        '';
        # proxy_set_header X-Real-IP $remote_addr;
        # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # proxy_set_header X-Forwarded-Proto https;
        # proxy_set_header X-Forwarded-Ssl on;
        # proxy_set_header X-Forwarded-Port $server_port;
        # proxy_set_header X-Forwarded-Host $host;
        # proxy_set_header Host $host;
        # proxy_set_header origin $http_origin;
        # proxy_set_header X-XSRF-TOKEN $http_x_xsrf_token;
        proxyPass = "http://${config.link.serviceHost}:${toString config.link.services.gitlab.port}/";
        proxyWebsockets = true;
      };
      #       extraConfig = ''
      # proxy_hide_header Content-Security-Policy "";
      #       '';
    };
    "audiobookshelf.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:4124/";
        proxyWebsockets = true;
      };
    };
    "crypt.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:5000/";
      };
      # proxyWebsockets = true;
      locations."/cryptpad_websocket" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:5001/";
        proxyWebsockets = true;
      };
      extraConfig = commonExtraConfig + ''
        add_header X-Content-Type-Options nosniff always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options sameorigin;
        add_header Content-Security-Policy "default-src 'none'; style-src 'unsafe-inline' 'self' https://crypt.alinkbetweennets.de;font-src 'self' data: https://crypt.alinkbetweennets.de; child-src https://crypt.alinkbetweennets.de; frame-src 'self' blob: https://cryptui.alinkbetweennets.de; script-src 'self' resource: https://crypt.alinkbetweennets.de; script-src-elem 'self' blob: 'unsafe-inline' resource: https://crypt.alinkbetweennets.de;img-src 'self' data: blob: https://crypt.alinkbetweennets.de; worker-src 'self';media-src blob: ; frame-ancestors 'self' https://crypt.alinkbetweennets.de;connect-src 'self' blob: https://crypt.alinkbetweennets.de https://cryptui.alinkbetweennets.de wss://crypt.alinkbetweennets.de;" always;
      '';
      #'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-h5wSYKWbmHcoYTdkHNNguMswVNCphpvwW+uxooXhF/Y=' 'sha256-rW/8eO/obXWbRoQlT2KlWVWmbqV+LGgiC1r8kKRsJhc=' 'sha256-OGjU0xQxuhdJDf8iMcgZXmRJZD2QZBQJRLwrFlOBLkI=' 'sha256-fWlVIwe2LsO09S7H48jPEdZpXqvWNASN9MJtP9UqorQ=' 'sha256-EzOdKxNif8wH7zIpBWq8C8s7ReXFFUgKIeh3S8mbzmg=' 'sha256-XqyszejV2KjHp1R/rjEZrlZr+jaJpoSSF34CliTkwsA=' 'sha256-550mecyv+58pd1gBLH1QBIOUYSFa6dRGnPr5EQydW1Y=' 'sha256-OEAthcFABIfn7TlCbTV6bGAv1qO5kVS02Tbru9uBM7E=' 'sha256-+ac8khtNoT0aNZRgSgtufqMcKat1zoMcy2QKOy1king=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-R5+O+GguAMEaEziO1n5XU7JdxbmNH9PrD0455tGIo+Y=' 'sha256-R/9llE0s4++pxJWFqpVdB+eQJk2ANaxrUkOoEgbf4BE=' 'sha256-Y1z0SyVx5S7ywM8HEuxVVkmBpqUjj6qZLBNBVk8E6h8=' 'sha256-ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=' 'sha256-tq5fHKUNWCWMHbqZJgps3MZdMB//nQ7ZNRkFNo18098='
    };
    "cryptui.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:5000/";
        proxyWebsockets = true;
      };
      extraConfig = commonExtraConfig + ''
        add_header X-Content-Type-Options nosniff always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options sameorigin;
        add_header Content-Security-Policy "default-src 'none'; style-src 'unsafe-inline' 'self' https://crypt.alinkbetweennets.de;font-src 'self' data: https://crypt.alinkbetweennets.de; child-src https://crypt.alinkbetweennets.de; frame-src 'self' blob: https://cryptui.alinkbetweennets.de; script-src 'self' resource: https://crypt.alinkbetweennets.de 'unsafe-eval' 'unsafe-inline';script-src-elem 'self' 'unsafe-inline' resource: https://crypt.alinkbetweennets.de;img-src 'self' data: blob: https://crypt.alinkbetweennets.de; worker-src 'self';media-src blob: ; frame-ancestors 'self' https://crypt.alinkbetweennets.de;connect-src 'self' blob: https://crypt.alinkbetweennets.de https://cryptui.alinkbetweennets.de wss://crypt.alinkbetweennets.de;" always;

      '';
    };
    # "cast.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8888/";
    #     proxyWebsockets = true;
    #   };
    # };
    "cyyyyyber.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      root = "${pkgs.cyberchef}/share/cyberchef";
      extraConfig = commonExtraConfig + ''
        add_header X-Content-Type-Options nosniff always;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Frame-Options sameorigin;
        add_header Content-Security-Policy "frame-ancestors 'self' resource: blob: https://*.alinkbetweennets.de ws://*.alinkbetweennets.de ; object-src 'none'; default-src 'self' 'unsafe-inline' 'unsafe-eval' resource: data: blob: https://*.alinkbetweennets.de ws://*.alinkbetweennets.de https://tiles.immich.cloud https://static.immich.cloud https://api-l.cofractal.com https://maputnik.github.io https://fonts.openmaptiles.org https://fonts.googleapis.com ; script-src 'self' resource: blob: https://*.alinkbetweennets.de ws://*.alinkbetweennets.de ; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' resource: blob: https://*.alinkbetweennets.de ws://*.alinkbetweennets.de ; font-src https://fonts.openmaptiles.org https://fonts.googleapis.com https://fonts.gstatic.com 'self' 'unsafe-inline' 'unsafe-eval' data: blob: ; img-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https://videos.owncast.online https://www.gravatar.com https://logo.clearbit.com https://*.alinkbetweennets.de ws://*.alinkbetweennets.de ; frame-src 'self' 'unsafe-inline' https://*.alinkbetweennets.de ws://*.alinkbetweennets.de https://www.youtube.com https://youtube.com https://www.youtu.be ; media-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https://assets.owncast.tv https://videos.owncast.online https://www.gravatar.com https://logo.clearbit.com https://*.alinkbetweennets.de ws://*.alinkbetweennets.de ; base-uri 'self' *.alinkbetweennets.de alinkbetweennets.de;" always;
      '';
    };
    # "bettuna.${config.link.domain}" = {
    #   quic = true;
    #   http3_hq = true;
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   root = "/var/www/bettuna";
    # };
    "timertest.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      http3 = true;
      # enableACME = true;
      serverAliases = [
      ];
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      root = "/var/www/timer/";
    };
    "timertest-coep.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      http3 = true;
      # enableACME = true;
      serverAliases = [
      ];
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig + ''
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        add_header X-Frame-Options sameorigin;
        add_header X-Content-Type-Options nosniff always;
      '';
      root = "/var/www/timer/";
    };
    "sca-lab.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      http3 = true;
      # enableACME = true;
      serverAliases = [
      ];
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      root = "/var/www/sca-lab-browser/ileakage";
    };
    "ileakage.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      http3 = true;
      # enableACME = true;
      serverAliases = [
      ];
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      root = "/var/www/ileakage/";
    };
    "burp.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      http3 = true;
      # enableACME = true;
      serverAliases = [
        "burpsuite.${config.link.domain}"
        "webhacking.${config.link.domain}"
        "xn--w38h.${config.link.domain}"
      ];
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      root = "/var/www/Vortrag-Burpsuite";
    };
    "jurij.${config.link.domain}" = {
      quic = true;
      http3_hq = true;
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      root = "/var/www/jurij";
    };
    # "lockpicking.${config.link.domain}" = {
    #   # enableACME = true;
    #   serverAliases = [
    #     "vortrag-lockpicking.${config.link.domain}"
    #     "xn--e18h.${config.link.domain}"
    #   ];
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   root = "/var/www/Vortrag-Lockpicking";
    # };
    "hedgedoc.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:${toString config.link.services.hedgedoc.port}";
        proxyWebsockets = true;
      };
    };
    # "jellyfin.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   listen = [
    #     {
    #       port = 443;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #     {
    #       port = 8096;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #     {
    #       port = 8920;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #   ];
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8096/";
    #   locations."/".proxyWebsockets = true;
    # };
    # "jellyfin1.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8096/";
    # };
    # "jellyfin2.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8920/";
    # };
    # "jellyseerr.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:5055/";
    #   locations."/".proxyWebsockets = true;
    # };
    "restic.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:2500/";
      };
      locations."/".proxyWebsockets = true;
    };
    "microbin.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:9483/";
      };
    };
    "ctf.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        # proxyPass = "http://unix:"+config.services.anubis.instances.ctf.settings.BIND;
        proxyPass = "http://192.168.2.15:8000/";
      };
      locations."/".proxyWebsockets = true;
    };
    "karsten.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://100.98.48.88:5000/";
      };
      locations."/".proxyWebsockets = true;
    };
    "kasten.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://100.98.35.19:5000/";
      };
      locations."/".proxyWebsockets = true;
    };
    "immich.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:${toString config.link.services.immich.port}";
        proxyWebsockets = true;
      };
    };
    "minio.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:9002";
        proxyWebsockets = true;
      };
    };
    "s3.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:9001";
        # extraConfig = ''
        #   proxy_set_header X-Real-IP $remote_addr;
        #   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #   proxy_set_header X-Forwarded-Proto $scheme;
        #   # proxy_set_header Host $host;
        #   proxy_connect_timeout 300;
        #   # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
        #   # proxy_http_version 1.1;
        #   proxy_set_header Connection "";
        #   chunked_transfer_encoding off;
        # '';
        proxyWebsockets = true;
      };
      # extraConfig = ''
      #   # To allow special characters in headers
      #   ignore_invalid_headers off;
      #   # Allow any size file to be uploaded.
      #   # Set to a value such as 1000m; to restrict file size to a specific value
      #   client_max_body_size 0;
      #   # To disable buffering
      #   proxy_buffering off;
      # '';
    };
    # "diagrams.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    #   locations."/" ={extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8765";
    # };
    "nextcloud.${config.link.domain}" = {
      # enableACME = true;
      useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://${config.link.serviceHost}:80";
      };
    };
    # "outline.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${
    #         toString config.link.services.outline.port
    #       }";
    #     proxyWebsockets = true;
    #   };
    # };
    # "vaultwarden.${config.link.domain}" = {
    #   # enableACME = true;
    #   useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${
    #         toString config.link.services.vaultwarden.port
    #       }";
    #     proxyWebsockets = true;
    #   };
    # };
    "alinkbn.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://100.98.48.88:5000/";
        proxyWebsockets = true;
      };
      extraConfig = commonExtraConfig + "";
      locations."/error" = {
        return = "302 https://www.youtube.com/watch?v=dQw4w9WgXcQ"; # rick
      };
    };
    "shonk.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://100.98.48.88:5000/";
        proxyWebsockets = true;
      };
      extraConfig = commonExtraConfig + "error_page 404 403 504 505 = @error;";
      locations."@error" = {
        return = "301 https://www.youtube.com/watch?v=yKobOh9D87Q"; # spinny sharkü
      };
    };
    # "shonk.de" = {
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   enableACME = true;
    #   listen = [
    #     {
    #       port = 443;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #     {
    #       port = 8096;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #     {
    #       port = 8920;
    #       addr = "0.0.0.0";
    #       ssl = true;
    #     }
    #   ];
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8096/";
    #     proxyWebsockets = true;
    #   };
    # };
    "${config.link.domain}" = {
      enableACME = true;
      # useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      default = true;
      locations."/" = {
        return = "302 https://www.youtube.com/watch?v=dQw4w9WgXcQ"; # rick
      };
    };
    # services.nginx.virtualHosts."paperless.${config.link.domain}" = {
    #   enableACME = true;
    # useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:${toString config.link.services.paperless.port}";
    #     proxyWebsockets = true;
    #   };
    # };

    # CTF
    "slides.netintro.${config.link.domain}" = {
      enableACME = true;
      # useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      # default = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://192.168.2.15:31337/";
      };
    };
    "vpnconfig.netintro.${config.link.domain}" = {
      enableACME = true;
      # useACMEHost = config.link.domain;
      forceSSL = true;
      extraConfig = commonExtraConfig;
      # default = true;
      locations."/" = {
        extraConfig = commonLocationExtraConfig;
        proxyPass = "http://192.168.2.15:31338/";
      };
    };
    # /CTF

    # "speedtest.${config.link.domain}" = {
    #   enableACME = true;
    # useACMEHost = config.link.domain;
    #   forceSSL=true;
    # extraConfig = commonExtraConfig;
    #   locations."/" = {
    #     extraConfig = commonLocationExtraConfig;
    # proxyPass = "http://${config.link.serviceHost}:8766";
    #   };
  };
  # services.anubis = {
  #   instances = {
  #     "ctf" = {
  #       enable = true;
  #       settings.TARGET = "http://192.168.2.15:8000";
  #     };
  #     "gitlab" = {
  #       enable = true;
  #       settings = {
  #         TARGET = "http://${config.link.serviceHost}:9002";
  #       };
  #     };
  #   };
  # };
  # services.oauth2-proxy={
  #   enable=true;
  # };
  services.teamspeak3 = {
    # enable = true;
    openFirewall = true;
    # openFirewallServerQuery = true;
    querySshPort = 10022;
    queryPort = 10011;
    queryHttpPort = 10080;
    fileTransferPort = 30033;
    defaultVoicePort = 9987;
    dataDir = "/var/lib/teamspeak3";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu+WcpENdr7FaCIwj6WsinGnykIPV/tnIyrfEHSeU+E root@sn"
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "23.11";
}
