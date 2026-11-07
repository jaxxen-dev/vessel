/* SPDX-License-Identifier: MIT
 * Copyright (C) 2026 Jaxxen
 */

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "4G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
                "nosuid"
                "nodev"
                "noexec"
              ];
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              randomEncryption = true;
              discardPolicy = "both";
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              extraFormatArgs = [
                "--cipher"
                "aes-xts-plain64"
                "--key-size"
                "512"
                "--hash"
                "sha256"
                "--pbkdf"
                "argon2id"
                "--iter-time"
                "5000"
              ];
              content = {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "nixos"
                  "-f"
                ];
                postCreateHook = ''
                  (
                    MNTPOINT=$(mktemp -d)
                    mount "$device" "$MNTPOINT" -o subvol=/
                    trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
                    btrfs property set "$MNTPOINT/@blank" ro true
                  )
                '';
                subvolumes = let
                  mountOptions = [
                    # "noatime"
                    "compress=zstd:1"
                    "space_cache=v2"
                    "discard=async"
                  ];
                in {
                  "@" = {
                    mountpoint = "/";
                    inherit mountOptions;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = mountOptions ++ [
                      "nosuid"
                      "nodev"
                    ];
                  };
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = mountOptions ++ [
                      "nosuid"
                      "nodev"
                    ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = mountOptions ++ [
                      "nosuid"
                      "nodev"
                    ];
                  };
                  "@blank" = {};
                };
              };
            };
          };
        };
      };
    };
  };
}
