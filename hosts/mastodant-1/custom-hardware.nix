{ config, lib, pkgs, modulesPath, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications
    
    # Mesa drivers for AMD
    extraPackages = with pkgs; [
      amdvlk          # AMD's official Vulkan driver
      rocmPackages.clr.icd  # OpenCL support
    ];
    
    # 32-bit Mesa drivers
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
  
  # Enable OpenCL support
  hardware.amdgpu.opencl.enable = true;
}