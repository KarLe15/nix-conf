{ config, lib, pkgs, modulesPath, ... }: {
  # Enable AMD GPU support
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" "amdgpu" ];

  boot.kernel.sysctl = {
    # Increase map count for games like CS2, Elden Ring
    "vm.max_map_count" = 2147483642;
    # Reduce swappiness for better gaming performance
    "vm.swappiness" = 10;
    # Network optimizations
    "net.core.rmem_default" = 31457280;
    "net.core.rmem_max" = 134217728;
  };
  
  boot.kernelParams = [
    # Power management for Suspend / Listed by Claude
    "acpi_sleep=nonvs" 
    "acpi_osi=Linux"
    "acpi.ec_no_wakeup=1"
    "mem_sleep_default=deep"
    # Better CPU power management
    "amd_pstate=active"  
    "amdgpu.si_support=1"
    "amdgpu.cik_support=1"
    "radeon.si_support=0"
    "radeon.cik_support=0"
  ];
}