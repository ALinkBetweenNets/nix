{ lib, pkgs, config, system-config, ... }:
with lib;
let cfg = config.link.gaming;
in {
  options.link.gaming.enable = mkEnableOption "enable gaming";
  config = mkIf cfg.enable {
    # Prism saves absolute Java paths per instance. Refresh Nix-provided
    # runtimes after upgrades so an old libc cannot prevent Mesa from loading.
    home.activation.refreshPrismJava = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for settings in \
        "${config.xdg.dataHome}/PrismLauncher/prismlauncher.cfg" \
        "${config.xdg.dataHome}/PrismLauncher/instances/"*/instance.cfg
      do
        [ -f "$settings" ] || continue
        javaPath=$(${lib.getExe pkgs.crudini} --get "$settings" General JavaPath 2>/dev/null) || continue
        case "$javaPath" in
          /nix/store/*-openjdk-8u*/*) java=${pkgs.jdk8}/bin/java ;;
          /nix/store/*-openjdk-17.*/*) java=${pkgs.jdk17}/bin/java ;;
          /nix/store/*-openjdk-21.*/*) java=${pkgs.jdk21}/bin/java ;;
          /nix/store/*-openjdk-25.*/*) java=${pkgs.jdk25}/bin/java ;;
          *) continue ;;
        esac
        if [ "$javaPath" != "$java" ]; then
          run ${pkgs.coreutils}/bin/cp --update=none "$settings" "$settings.before-java-refresh"
          run ${lib.getExe pkgs.crudini} --set "$settings" General JavaPath "$java"
          if ${lib.getExe pkgs.crudini} --get "$settings" General JavaSignature >/dev/null 2>&1; then
            run ${lib.getExe pkgs.crudini} --del "$settings" General JavaSignature
          fi
        fi
      done
    '';
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
