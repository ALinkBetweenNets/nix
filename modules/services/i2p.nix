{ config, system-config, pkgs, lib, ... }:
with lib;
let cfg = config.link.i2p;
in {
  options.link.i2p = {
    enable = mkEnableOption "activate i2p";
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
      default = 5500;
      description = "port to run the application on";
    };
  };
  config = mkIf cfg.enable {
    containers.i2pd-container = {
      # autoStart = true;
      config = { ... }: {
        system.stateVersion =
          "23.05"; # If you don't add a state version, nix will complain at every rebuild
        # Exposing the nessecary ports in order to interact with i2p from outside the container
        networking.firewall.allowedTCPPorts = [
          7656 # default sam port
          7070 # default web interface port
          4444 # default http proxy port
          4447 # default socks proxy port
        ];
        services.i2pd = {
          enable = true;
          # address =
            # "127.0.0.1"; # you may want to set this to 0.0.0.0 if you are planning to use an ssh tunnel
          # proto = {
          #   http.enable = true;
          #   socksProxy.enable = true;
          #   httpProxy.enable = true;
          #   sam.enable = true;
          # };
        };
        services.kubo = { enable = true; };
      };
    };
  };
}
