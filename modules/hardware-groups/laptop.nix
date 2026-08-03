{
  config,
  flake-self,
  system-config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.link.laptop;
in
{
  options.link.laptop = {
    enable = mkEnableOption "activate laptop";
  };
  config = mkIf cfg.enable {
    boot.kernelParams = [
      "cfg80211.ieee80211_regdom=DE"
    ];
    networking.wireless.athUserRegulatoryDomain = true;
    networking.networkmanager.wifi.powersave = false;
    programs.captive-browser = {
      enable = true;
      interface = "wlp1s0";
    };
    boot.loader.timeout = 1; # was default 5s; hold Space at the menu to pick an older generation
    networking.dhcpcd.enable = false;
    services.hardware.bolt.enable = true;
    environment.systemPackages = with pkgs; [
      wireless-regdb
      kdePackages.kconfig
      kdePackages.plasma-thunderbolt

    ];
    boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
    boot.initrd.kernelModules = [ "evdi" ];
    environment.variables = {
      KWIN_DRM_PREFER_COLOR_DEPTH = "24";
    };
    systemd.services.displaylink-server = {
      enable = true;
      # Ensure it starts after udev has done its work
      requires = [ "systemd-udevd.service" ];
      after = [ "systemd-udevd.service" ];
      wantedBy = [ "multi-user.target" ]; # Start at boot
      # *** THIS IS THE CRITICAL 'serviceConfig' BLOCK ***
      serviceConfig = {
        Type = "simple"; # Or "forking" if it forks (simple is yecommon for daemons)
        # The ExecStart path points to the DisplayLinkManager binary provided by the package
        ExecStart = "${
          (pkgs.displaylink.overrideAttrs {
            src = pkgs.fetchurl {
              sha256 = "sha256-JQO7eEz4pdoPkhcn9tIuy5R4KyfsCniuw6eXw/rLaYE=";
              url = "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
            };
          })
        }/bin/DisplayLinkManager";
        # User and Group to run the service as (root is common for this type of daemon)
        User = "root";
        Group = "root";
        # Environment variables that the service itself might need
        # Environment = [ "DISPLAY=:0" ]; # Might be needed in some cases, but generally not for this
        Restart = "on-failure";
        RestartSec = 5; # Wait 5 seconds before restarting
      };
    };
    link = {
      desktop.enable = true;
      hardware.enable = true;
      # unbound.enable = true;
      #wg-fritz.enable = true;
    };
    #options.type = "laptop";
    #networking.wireless.enable = !config.networking.networkmanager.enable;
    networking.networkmanager = {
      wifi.macAddress = "stable";
    };
    hardware.bluetooth.enable = true;
    location.latitude = 50.0;
    location.longitude = 7.0;
    location.provider = "geoclue2";
    services = {
      geoclue2 = {
        enable = true;
        staticAccuracy = 10;
        staticAltitude = 95;
        enableStatic = lib.mkForce true;
      };
      ddccontrol.enable = true; # Control External Monitor Brightness
      libinput.enable = true;
      # power-profiles-daemon.enable = lib.mkForce false;
      tlp.enable = false;
      auto-cpufreq = {
        enable = false; # TLP replacement
        settings = {
          charger = {
            governor = "performance";
            turbo = "auto";
            energy_performance_preference = "performance";
            platform_profile = "performance";
          };
          battery = {
            governor = "powersave";
            turbo = "never";
            energy_performance_preference = "power";
            platform_profile = "low-power";
          };
        };
      };
    };
    powerManagement = {
      enable = true;
      #powertop.enable = true; # no option to disable usb powersaving yet
    };
    systemd.sleep.settings.Sleep = {
      AllowSuspend = "yes";
      AllowHibernation = "yes";
      AllowHybridSleep = "yes";
      AllowSuspendThenHibernate = "yes";
    };
  };
}
