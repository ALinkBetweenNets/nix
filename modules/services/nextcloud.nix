{ config, system-config, pkgs, lib, ... }:
with lib;
let cfg = config.link.services.nextcloud;
in {
  options.link.services.nextcloud = {
    enable = mkEnableOption "activate nextcloud";
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
      default = 80;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets."nextcloud" = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    services = {
      nextcloud-whiteboard-server = {
        enable = true;
        settings = {
          NEXTCLOUD_URL = "https://nextcloud.${config.link.domain}";
        };
      };
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud34;
        hostName = "nextcloud.${config.link.domain}";
        settings.trusted_proxies = [ "100.86.79.82" ];
        config = {
          dbtype = "sqlite";
          adminuser = "l";
          adminpassFile = config.sops.secrets."nextcloud".path;
        };
        datadir = "${config.link.storage}/nextcloud-data";
        #secretFile = "${config.link.secrets}/nextcloud-secrets.json";
        extraApps = with config.services.nextcloud.package.packages.apps; {
          inherit bookmarks calendar deck mail notes onlyoffice polls tasks
            twofactor_webauthn contacts;
        };
        #extraOptions = {
        #  mail_smtpmode = "sendmail";
        #  mail_sendmailmode = "pipe";
        #};
        extraAppsEnable = true;
        autoUpdateApps.enable = true;
        appstoreEnable = true;
        https = true;
        configureRedis = true;
        database.createLocally = true;
        home = "${config.link.storage}/nextcloud";
      };
      nginx =
        if (!cfg.nginx) then {
          enable = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = false;
          logError = "stderr debug";
          #package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
          clientMaxBodySize = "1000m";
          commonHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            # Adding this header to HTTP requests is discouraged
              server_names_hash_bucket_size 128;
              proxy_headers_hash_max_size 1024;
              proxy_headers_hash_bucket_size 256;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
          '';
          virtualHosts."nextcloud.${config.link.domain}" = {
            # enableACME = true;
            # forceSSL = true;
            extraConfig = mkIf (!cfg.nginx-expose) ''
              allow ${config.link.service-ip}/24;
              allow 127.0.0.1;
              deny all; # deny all remaining ips
            '';
            #locations."/" = {
            #  proxyPass = "http://127.0.0.1:80/";
            # extraConfig = ''
            #   proxy_set_header Front-End-Https on;
            #   proxy_set_header Strict-Transport-Security "max-age=2592000; includeSubdomains";
            #   proxy_set_header X-Real-IP $remote_addr;
            #   proxy_set_header Host $host;
            #   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            #   proxy_set_header X-Forwarded-Proto $scheme;
            # '';
            #};
          };
        } else {
          virtualHosts."nextcloud.${config.link.domain}" = {
            enableACME = true;
            forceSSL = true;
            extraConfig = mkIf (!cfg.nginx-expose) ''
              allow ${config.link.service-ip}/24;
              allow 127.0.0.1;
              deny all; # deny all remaining ips
            '';
            #locations."/" = {
            #  proxyPass = "http://127.0.0.1:80/";
            # extraConfig = ''
            #   proxy_set_header Front-End-Https on;
            #   proxy_set_header Strict-Transport-Security "max-age=2592000; includeSubdomains";
            #   proxy_set_header X-Real-IP $remote_addr;
            #   proxy_set_header Host $host;
            #   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            #   proxy_set_header X-Forwarded-Proto $scheme;
            # '';
            #};
          };
        };
    };
    security.acme = mkIf (!cfg.nginx) {
      acceptTerms = true;
      defaults.email = "link2502+acme@proton.me";
    };
    networking.firewall.interfaces."${config.link.service-interface}".allowedTCPPorts =
      mkIf cfg.expose-port [ cfg.port ];
  };
}
