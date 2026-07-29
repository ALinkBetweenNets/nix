{ config, system-config, pkgs, lib, ... }:
with lib;
let cfg = config.link.plymouth;
adiTarget2 = pkgs.adi1090x-plymouth-themes.override {
  selected_themes = [ "target_2" ];
};

patchedTarget2 = adiTarget2.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    cp ${./target_2.script} \
      $out/share/plymouth/themes/target_2/target_2.script
    '';
  });

in {
  options.link.plymouth = { enable = mkEnableOption "activate plymouth"; };
  config = mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
        themePackages = with pkgs;
          [
            # By default we would install all themes
            # (adi1090x-plymouth-themes.override {
              # selected_themes = [ "target_2" ];
            # })
            patchedTarget2
          ];
        theme = "target_2";
        # logo = pkgs.fetchurl {
        #   url = "https://nixos.org/logo/nixos-hires.png";
        #   sha256 = "1ivzgd7iz0i06y36p8m5w48fd8pjqwxhdaavc0pxs7w1g7mcy5si";
        # };
      };
      kernelParams = [
        "splash"
        "rd.systemd.show_status=auto"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];
      loader.timeout = lib.mkForce 0;
    };
  };
}
