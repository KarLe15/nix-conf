{ config, lib, pkgs, modulesPath, ... }: {
  services.lvm.enable = true;

  boot.zfs.extraPools = [ "data_pool" ];

  fileSystems."/mnt/archives" = {
    device = "/dev/archives-vg/archives-lv";
    fsType = "xfs";
    options = [ "defaults" "noatime" "largeio" "inode64" ];
  };
  
  fileSystems."/mnt/data_pool" = {
    device = "data_pool";
    fsType= "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/mnt/repos" = {
    device = "/dev/disk/by-uuid/9e8525a1-c002-4e29-b766-2aa91019b4e5";
    fsType= "btrfs";
    options = [ "subvol=/" "compress=zstd" "noatime" ];
  };

  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-uuid/f3b17cfa-cc7f-4995-9b24-88d4fca7340e";
    fsType= "xfs";
    options = [ "noatime" "largeio" "inode64" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/repos 0755 karim users -"
    "d /mnt/media 0755 karim users -"
    "d /mnt/archives 0755 karim users -"
    "d /mnt/data_pool 0755 karim users -"
    "Z /mnt/data_pool 0755 karim users -"
  ];



  systemd.services.fix-archives-permissions = {
    description = "Fix /mnt/archives permissions";
    after = [ "mnt-archives.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/chown karim:users /mnt/archives";
    };
  };
}