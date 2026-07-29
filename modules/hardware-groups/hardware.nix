{ config, system-config, pkgs, lib, ... }:
with lib;
let cfg = config.link.hardware;
in {
  options.link.hardware.enable = mkEnableOption "activate hardware";
  config = mkIf cfg.enable {
    link.libvirt.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs;
      [
        # powertop
        lm_sensors
        cpufrequtils
      ] ++ lib.optionals (config.link.desktop.enable) [ cpupower-gui ];
    time.hardwareClockInLocalTime = false;
    services = {
      # for windows dualboot
      # hardware.enableRedistributableFirmware = true;
      fwupd.enable =
        config.link.systemd-boot.enable; # fwupd does not work in BIOS mode
      smartd.enable = lib.mkDefault true;
      udisks2.enable = true;
    };
    hardware = {
      enableAllFirmware = true;
      sensor.hddtemp = {
        enable = true;
        drives = [ "/dev/disk/by-id/*" ];
      };
    };
    zramSwap.enable = true;
    # zram is RAM-speed; prefer it over dropping page cache under pressure.
    # The btrfs hibernation swapfile keeps its low priority, so it's only used
    # once zram fills — hibernation/resume_offset unaffected.
    # mkDefault so any host can still override.
    boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 150;
  };
}
