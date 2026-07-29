{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.plasma;
in
{
  options.link.plasma.enable = mkEnableOption "activate plasma";
  config = mkIf cfg.enable {
    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        # theme = "/home/l/aerial-sddm-theme/";
        # theme= "breeze";
      };
      desktopManager.plasma6.enable = true;
    };
    # DrKonqi's coredump pickup runs `--pickup` at every Plasma login and
    # processes the whole systemd-coredump backlog serially, stalling the
    # session for up to a minute. Mask it; live crash dialogs still work.
    systemd.user.services.drkonqi-coredump-pickup.enable = false;
    # Cap the coredump pool so it never grows unbounded again.
    systemd.coredump.settings.Coredump.MaxUse = "512M";
    environment.systemPackages = with pkgs; [
      kdePackages.sddm-kcm # sddm config module
      kdePackages.kirigami
      kdePackages.plasma-nm
      kdePackages.qtstyleplugin-kvantum
      kdePackages.qtmultimedia
    ];
    i18n.inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        # fcitx5-mozc
        fcitx5-gtk
        kdePackages.fcitx5-qt
      ];
    };
  };
}
