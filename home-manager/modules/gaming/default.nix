{ lib, pkgs, config, system-config, ... }:
with lib;
let cfg = config.link.gaming;
in {
  options.link.gaming.enable = mkEnableOption "enable gaming";
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        prismlauncher # minecraft launcher
        jdk17
        glibc # required for minecraft
        # protonup-qt
        # protontricks
        # winetricks
        # wine
        # wine64
        prismlauncher # minecraft launcher
        (lutris.override {
          extraLibraries = pkgs:
            [
              # List library dependencies here
            ];
        })
      ] ++ lib.optionals
        (system-config.nixpkgs.hostPlatform.system == "x86_64-linux") [ ];
  };
}
