{ config, pkgs, lib, ... }:
with lib;
let cfg = config.link.server;
in {
  options.link.server = { enable = mkEnableOption "activate server"; };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ rclone fuse ];
    link = {
      tailscale.enable = true;
      tailscale.routing = "server";
      # unbound.enable = true;
    };
    # programs.msmtp = { enable = true; };
  };
}
