{ config, lib, ... }:
with lib;
let cfg = config.link.services.shlink;
in {
  options.link.services.shlink = {
    enable = mkEnableOption "activate shlink";
    expose-port = mkOption {
      type = types.bool;
      default = config.link.service-ports-expose;
      description = "directly expose the port of the application";
    };
    nginx = mkOption {
      type = types.bool;
      default = config.link.nginx.enable;
      description =
        "expose the application to the internet with NGINX and ACME";
    };
    nginx-expose = mkOption {
      type = types.bool;
      default = config.link.nginx-expose;
      description = "expose the application to the internet";
    };
    port = mkOption {
      type = types.int;
      default = 8412;
      description = "port to run the application on";
    };
    client-port = mkOption {
      type = types.int;
      default = 8413;
      description = "port to run the web client on";
    };
    domain = mkOption {
      type = types.str;
      default = "s.${config.link.domain}";
      description = "domain used for the generated short urls";
    };
  };
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      shlink = {
        image = "ghcr.io/shlinkio/shlink:stable";
        autoStart = true;
        environment = {
          DEFAULT_DOMAIN = cfg.domain;
          IS_HTTPS_ENABLED = "true";
        };
        # INITIAL_API_KEY=...
        environmentFiles = [ config.sops.secrets."shlink".path ];
        # ponytail: sqlite (image default), postgres only if locking shows up in the logs
        volumes = [ "${config.link.storage}/shlink:/etc/shlink/data" ];
        ports = [ "${toString cfg.port}:8080" ];
      };
      shlink-web-client = {
        image = "ghcr.io/shlinkio/shlink-web-client:stable";
        autoStart = true;
        environment.SHLINK_SERVER_URL = "https://${cfg.domain}";
        ports = [ "${toString cfg.client-port}:8080" ];
      };
    };
    sops.secrets."shlink" = { };
    services.nginx.virtualHosts = mkIf cfg.nginx {
      "${cfg.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString cfg.port}";
      };
      "shlink.${config.link.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass =
          "http://127.0.0.1:${toString cfg.client-port}";
        extraConfig = mkIf (!cfg.nginx-expose) ''
          allow ${config.link.service-ip}/24;
          allow 127.0.0.1;
          deny all; # deny all remaining ips
        '';
      };
    };
    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port [ cfg.port cfg.client-port ];
  };
}
