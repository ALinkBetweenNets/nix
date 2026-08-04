{ config, lib, pkgs, ... }:
with lib;
let cfg = config.link.nginx;
in {
  # NGINX Snippet
  #  extraConfig = toString (
  #       optional config.link.nginx.geoIP ''
  #         if ($allowed_country = no) {
  #             return 444;
  #         }
  #       ''
  #     );
  options.link.nginx = { geoIP = mkEnableOption "enable GeoIP"; };
  config = mkIf cfg.geoIP {
    # when Nginx is enabled, enable the GeoIP updater service
    sops.secrets."maxmind-geoip-license" = {
      owner = "nginx";
      group = "nginx";
    };
    services.geoipupdate = mkIf cfg.enable {
      enable = true;
      interval = "weekly";
      settings = {
        EditionIDs = [ "GeoLite2-Country" ];
        AccountID = 952739;
        LicenseKey = {
          _secret = config.sops.secrets."maxmind-geoip-license".path;
        };
        DatabaseDirectory = "${config.link.storage}/GeoIP";
      };
    };
    # build nginx with geoip2 module
    services.nginx = {
      # package = pkgs.nginxStable.override (oldAttrs: {

      # });
      appendHttpConfig = toString ([
        # we want to load the geoip2 module in our http config, pointing to the database we are using
        # country iso code is the only data we need
        ''
          geoip2 ${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-Country.mmdb {
            $geoip2_data_country_iso_code country iso_code;
          }
        ''
        # we want to allow only requests from specific countries
        # if a request is not from such a country, we return no, which will result in a 403
        ''
          map $geoip2_data_country_iso_code $blocked_country {
            default 1;
            DE 0;
            NL 0;
            AT 0;
            LU 0;
          }
        ''
        # ''
        #   server {
        #     listen 0.0.0.0:80;
        #     listen [::0]:80;
        #     listen 0.0.0.0:443 ssl;
        #     listen [::0]:443 ssl;
        #     if ($blocked_country) {
        #         return 403;
        #     }
        #   }
        # ''
      ]);
    };
  };
}
