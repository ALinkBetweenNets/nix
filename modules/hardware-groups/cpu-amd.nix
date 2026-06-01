{ lib, pkgs, config, nixgl, ... }:
with lib;
let cfg = config.link.cpu-amd;
in {
  options.link.cpu-amd.enable = mkEnableOption "activate cpu-amd";
  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "amdgpu" ];
    environment.systemPackages = with pkgs; [ nvtopPackages.amd clinfo ];
    boot = {
      initrd.kernelModules = [ "amdgpu" ];
      kernelParams = [
        "amd_iommu=on"
        "amd_pstate=active"
        "amdgpu.gpu_recovery=1"
        # "amdgpu.runpm=0"
        # "amdgpu.dcdebugmask=0x10" # disable panel power saver refresh
        "amdgpu.dc=1" # Enable display Core (always reccommended)
        # "amdgpu.dpm=0" # dynamic power management
        # "amdgpu.mcbp=0" # memory clock bypass
        # "amdgpu.dcfeaturemask=0x8" # enable display power saver refresh
        # "amdgpu.dcdebugmask=0x10" # disable powersaving?, enable if crashes / issue / artifacts of the display, especially after hibernate/suspend
        # "amdgpu.sg_display=0" # enable if the screen flickers or stays white, not needed in kernel >=6.6
        # "radeon.cik_support=0" # for Sea islands (CIK) GPUs
        # "amdgpu.cik_support=1" # for Sea islands (CIK) GPUs
      ];
      extraModprobeConfig = "options kvm_amd nested=1";
      kernelModules = [ "kvm-amd" "amdgpu" ];
    };
    hardware = {
      cpu.amd.updateMicrocode = true;
      amdgpu.initrd.enable = lib.mkDefault true;
      amdgpu.opencl.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          mesa
          libva
          rocmPackages.clr.icd # OpenCL via ROCm ICD loader
          # rocmPackages.clr.icd
          # rocmPackages.clr
          # mesa.opencl
          libva-vdpau-driver
          libvdpau-va-gl
          libvdpau
        ];
      };
    };
  };
}
