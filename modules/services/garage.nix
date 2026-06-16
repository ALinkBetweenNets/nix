{ config, system-config, pkgs, lib, ... }:
with lib;
let cfg = config.link.services.garage;
in {
  options.link.services.garage = {
    enable = mkEnableOption "activate garage";
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
      default = 7825;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets."garage/rpc-secret" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."garage/admin-token" = {
      owner = "root";
      group = "root";
    };
    services = {
      garage = {
        enable = true;
        package = pkgs.garage_2;
        settings = {
          data_dir = "${config.link.storage}/garage/data";
          rpc_bind_addr = "0.0.0.0:${toString cfg.port}";
          rpc_secret_file = config.sops.secrets."garage/rpc-secret".path;
          s3_api.api_bind_addr = "0.0.0.0:${toString ( cfg.port+1)}";
          s3_api.s3_region = "de";
          s3_api.root_domain = "s3.alinkbetweennets.de";
          s3_web={
            bind_addr="0.0.0.0:${toString (cfg.port+2)}";
            root_domain="s3w.alinkbetweennets.de";
          };
          admin.admin_token_file = config.sops.secrets."garage/admin-token".path;
          replication_factor=1;
          compression_level=10;
        };
      };
      nginx.virtualHosts."garage.${config.link.domain}" = mkIf cfg.nginx {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9002";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            # proxy_set_header Host $host;
            proxy_connect_timeout 300;
            # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
            #proxy_http_version 1.1;
            proxy_set_header Connection "";
            chunked_transfer_encoding off;
          '';
        };
        extraConfig = ''
          # To allow special characters in headers
          ignore_invalid_headers off;
          # Allow any size file to be uploaded.
          # Set to a value such as 1000m; to restrict file size to a specific value
          client_max_body_size 0;
          # To disable buffering
          proxy_buffering off;
        '';
      };
    };
    networking.firewall = {
      # checkReversePath = lib.mkDefault "loose";
      # nameservers = [ "100.100.100.100" "1.1.1.1" ];
    };
    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port [ cfg.port (cfg.port+1) (cfg.port+2) ];
  };
}
