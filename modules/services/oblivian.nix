{ config, pkgs, lib, ... }:
with lib;
let cfg = config.link.services.oblivian;
in {
  options.link.services.oblivian = {
    enable = mkEnableOption "activate oblivian";
    expose-port = mkOption {
      type = types.bool;
      default = config.link.service-ports-expose;
      description = "directly expose the port of the application";
    };
    port = mkOption {
      type = types.int;
      default = 9850;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.oblivian = {
      description = "Oblivian vault sync server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        OBLIVIAN_LISTEN = "${
          if cfg.expose-port then "0.0.0.0" else "127.0.0.1"
        }:${toString cfg.port}";
        OBLIVIAN_DATA_DIR = "/var/lib/oblivian";
      };
      serviceConfig = {
        ExecStart = getExe pkgs.link.oblivian-server;
        DynamicUser = true;
        StateDirectory = "oblivian";
        Restart = "on-failure";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        CapabilityBoundingSet = "";
      };
    };
    networking.firewall.allowedTCPPorts = mkIf cfg.expose-port [ cfg.port ];
  };
}
